{-# LANGUAGE DuplicateRecordFields, RecordWildCards, FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables, ConstraintKinds, DataKinds, TypeOperators #-}
{-# LANGUAGE OverloadedStrings, OverloadedLists, QuasiQuotes, TypeFamilies #-}
{-# LANGUAGE LambdaCase #-}

-- | Incoming server implementation to provide an API for Era Glonass side
--   and also some debug stuff for internal usage.
module Carma.EraGlonass.Server
     ( serverApplicaton
     ) where

import           Data.Proxy
import           Data.Maybe (isNothing)
import           Data.Aeson (Value (String), encode)
import           Data.Swagger (Swagger)
import           Data.Char (toLower, toUpper)
import           Data.Text (Text)
import qualified Data.Text as T
import           Text.InterpolatedString.QM

import           Control.Monad (when, guard)
import           Control.Monad.Reader (MonadReader, asks, runReaderT, ReaderT)
import           Control.Monad.Error.Class (MonadError)
import           Control.Monad.Catch (MonadCatch)
import           Control.Monad.Random.Class (MonadRandom)
import           Control.Monad.Logger (LogSource)
import           Control.Concurrent.STM.TMVar
import           Control.Concurrent.STM.TVar

import           Database.Persist ((==.))
import           Database.Persist.Types
import qualified Database.Esqueleto as E

import           Network.HTTP.Types.Header (hContentType)
import           Network.HTTP.Media (renderHeader)

import           Servant
import           Servant.Swagger (HasSwagger (toSwagger))

import           Carma.Monad.STM
import           Carma.Monad.Clock
import           Carma.Monad.Thread
import           Carma.Monad.LoggerBus (MonadLoggerBus)
import qualified Carma.Monad.LoggerBus as LoggerBus
import           Carma.Monad.PersistentSql
import           Carma.Monad.Esqueleto
import           Carma.EraGlonass.Instances ()
import           Carma.EraGlonass.Helpers
import           Carma.EraGlonass.Routes
import           Carma.EraGlonass.Model.CaseEraGlonassFailure.Persistent
import           Carma.EraGlonass.Server.Helpers (runSqlProtected)
import           Carma.EraGlonass.Server.ReceiveRequestForServiceRequest
import           Carma.EraGlonass.Types.AppContext (AppContext (..))
import           Carma.EraGlonass.Types.EGBindVehiclesRequest
import           Carma.EraGlonass.Types.EGMayFailToParse
import           Carma.EraGlonass.Types.RouteActionResponse
import           Carma.EraGlonass.Types.Helpers.DateTime (showRFC3339DateTime)
import           Carma.EraGlonass.Types.TurnedOffResponse
import           Carma.EraGlonass.Model.Types (biggestPgArrayItem)


type FaliuresAPI
   = -- GET /debug/failures/count.json
     "count.json" :> Get '[JSON] Word

   # -- GET /debug/failures/list.json?limit=10
     "list.json"
     :> QueryParam "limit" Word
     :> Get '[JSON] [Entity CaseEraGlonassFailure]


type ServerAPI
   = IncomingAPI

   # "debug" :> ( "swagger"
                  :> ( -- GET /debug/swagger/incoming.json
                       "incoming.json" :> Get '[JSON] Swagger

                     # -- GET /debug/swagger/outcoming.json
                       "outcoming.json" :> Get '[JSON] Swagger
                     )

                # "failures" :> FaliuresAPI

                # -- GET /debug/background-tasks/count.json
                  "background-tasks" :> "count.json" :> Get '[JSON] Word

                # -- POST /debug/vin-synchronizer/trigger.json
                  "vin-synchronizer" :> "trigger.json"
                  :> Post '[JSON] RouteActionResponse

                # -- POST /debug/status-synchronizer/trigger.json
                  "status-synchronizer" :> "trigger.json"
                  :> Post '[JSON] RouteActionResponse
                )


-- | All monads constraints of all handlers.
type ServerMonad m =
   ( MonadReader AppContext m
   , MonadLoggerBus m
   , MonadError ServerError m
   , MonadCatch m
   , MonadPersistentSql m
   , MonadEsqueleto m
   , MonadClock m
   , MonadRandom m
   , MonadThread m
   , MonadSTM m
   )


serverApplicaton :: AppContext -> Application
serverApplicaton appContext =
  serve api $ hoistServer api withReader server
  where api = Proxy :: Proxy ServerAPI

        withReader :: ReaderT AppContext Handler a -> Handler a
        withReader r = runReaderT r appContext


server :: ServerMonad m => ServerT ServerAPI m
server
  = receiveRequestForServiceRequest
  # ( (incomingSwagger  # outcomingSwagger)
    # (getFailuresCount # getFailuresList)
    # getBackgroundTasksCount
    # vinSynchronizerTrigger
    # statusSynchronizerTrigger
    )


incomingSwagger :: Applicative m => m Swagger
incomingSwagger = pure $ toSwagger (Proxy :: Proxy IncomingAPI)

outcomingSwagger
  :: forall m final xs
   .
   ( Applicative m

   , OutcomingAPI ~
       ( "bindVehicles" :>
       ( ReqBody '[JSON] (EGBindVehiclesRequest 'Bind)
           :> Post '[JSON] (EGMayFailToParse (EGBindVehiclesResponse 'Bind))
       # ReqBody '[JSON] (EGBindVehiclesRequest 'Unbind)
           :> Post '[JSON] (EGMayFailToParse (EGBindVehiclesResponse 'Unbind))
       )
       # xs
       )

   , -- Fixing clashing routes with same URL.
     final ~
       ( "bindVehicles" :>
       ( ReqBody '[JSON] (
           Either (EGBindVehiclesRequest 'Bind)
                  (EGBindVehiclesRequest 'Unbind)
         ) :> Post '[JSON] (EGMayFailToParse (
                Either (EGBindVehiclesResponse 'Bind)
                       (EGBindVehiclesResponse 'Unbind)
              ))
       )
       # xs
       )

   , HasSwagger final
   )
  => m Swagger

outcomingSwagger = pure $ toSwagger (Proxy :: Proxy final)


getFailuresCount
  ::
   ( MonadReader AppContext m
   , MonadLoggerBus m
   , MonadError ServerError m
   , MonadPersistentSql m
   )
  => m Word

getFailuresCount = do
  srcLogDebug [qn| Obtaining EG failures total count... |]

  totalCount <-
    fromIntegral <$>
      runSqlProtected logSrc
        [qn| Failed to request EG failures total count! |]
        (count ([] :: [Filter CaseEraGlonassFailure]))

  srcLogDebug [qm| Total EG failures is obtained: {totalCount} |]
  pure totalCount


getFailuresList
  ::
   ( MonadReader AppContext m
   , MonadLoggerBus m
   , MonadError ServerError m
   , MonadPersistentSql m
   , MonadEsqueleto m
   )
  => Maybe Word
  -> m [Entity CaseEraGlonassFailure]

getFailuresList Nothing = do
  srcLogError [qns|
    Attempt to obtain EG failures list without specified limit!
  |]

  throwError err400
    { errBody = [qns| Getting EG failures list
                      without specified limit isn't allowed! |] }

getFailuresList (Just n) = do
  srcLogDebug [qm| Obtaining EG failures list limited to last {n} elements... |]

  result <-
    runSqlProtected logSrc [qn| Failed to request EG failures list! |] $ do
      -- To avoid @null@s being placed on top of the order
      withRepeats <-
        esqueletoSelect $
        E.from $ \failure -> do

        E.where_ ( E.not_ $ E.isNothing $
                     failure E.^. CaseEraGlonassFailureRepeats
                 )

        E.orderBy [ E.desc $ failure `biggestPgArrayItem`
                               CaseEraGlonassFailureRepeats

                  , E.desc $ failure E.^. CaseEraGlonassFailureCtime
                  ]

        E.limit $ fromIntegral n
        pure failure

      -- To avoid @null@s being placed on top of the order
      withoutRepeats <-
        selectList [ CaseEraGlonassFailureRepeats ==. Nothing
                   ]
                   [ Desc CaseEraGlonassFailureCtime
                   , LimitTo $ fromIntegral n - length withRepeats
                   ]

      pure $ withRepeats <> withoutRepeats

  srcLogDebug [qms|
    EG failures list is obtained, total elements: {length result}
  |]

  pure result


getBackgroundTasksCount
  ::
   ( MonadReader AppContext m
   , MonadLoggerBus m
   , MonadSTM m
   )
  => m Word

getBackgroundTasksCount = do
  srcLogDebug [qn| Reading background tasks counter... |]
  result <- asks backgroundTasksCounter >>= atomically . readTVar
  srcLogDebug [qm| Background tasks count: {result} |]
  pure result


vinSynchronizerTrigger
  :: forall m
   .
   ( MonadReader AppContext m
   , MonadLoggerBus m
   , MonadClock m
   , MonadSTM m
   , MonadError ServerError m
   )
  => m RouteActionResponse

vinSynchronizerTrigger = go where
  go =
    asks vinSynchronizerTriggerBus >>=
      maybe err (manuallyTrigger (False, "VIN synchronization"))

  errMsg = [qms|
    Cannot trigger {VinSynchronizer}
    because it is turned off by the config
  |]

  err =
    throwError err503
      { errHeaders = pure $
          (hContentType, renderHeader $ contentType (Proxy :: Proxy JSON))

      , errBody = encode $ TurnedOffResponse errMsg VinSynchronizer
      }


statusSynchronizerTrigger
  :: forall m
   .
   ( MonadReader AppContext m
   , MonadLoggerBus m
   , MonadClock m
   , MonadSTM m
   , MonadError ServerError m
   )
  => m RouteActionResponse

statusSynchronizerTrigger = go where
  go =
    asks statusSynchronizerTriggerBus >>=
      maybe err (manuallyTrigger (True, "statuses synchronization"))

  errMsg = [qms|
    Cannot trigger {StatusSynchronizer}
    because it is turned off by the config
  |]

  err =
    throwError err503
      { errHeaders = pure $
          (hContentType, renderHeader $ contentType (Proxy :: Proxy JSON))

      , errBody = encode $ TurnedOffResponse errMsg StatusSynchronizer
      }

manuallyTrigger
  :: forall m t
   .
   ( MonadLoggerBus m
   , MonadClock m
   , MonadSTM m
   , MonadError ServerError m
   , t ~ RouteActionResponse
   )
  => (Bool, Text) -- ^ @Bool@ menas it can be capitalized
  -> TMVar UTCTime
  -> m t

manuallyTrigger (isCapitalizable, actionTitle) bus = do
  let (capitalizedActionTitle, uncapitalizedActionTitle) =
        maybe (actionTitle, actionTitle)
              (\(x, xs) -> (toUpper x `T.cons` xs, toLower x `T.cons` xs))
              (guard isCapitalizable *> T.uncons actionTitle)

  srcLogDebug [qm| Triggering {uncapitalizedActionTitle} manually... |]

  lastTriggerTime <-
    getCurrentTime >>= \currentTime -> atomically $ do
      lastTime <- tryReadTMVar bus

      when (isNothing lastTime) $
        putTMVar bus currentTime

      pure $ maybe (Left currentTime) Right lastTime

  case lastTriggerTime of
       Left currentTime -> do
         let rfc3339Time = showRFC3339DateTime currentTime

         srcLogDebug [qms|
           {capitalizedActionTitle} is successfully manually triggered at
           {rfc3339Time}.
         |]

         let msg = [qm| {capitalizedActionTitle} is successfully triggered. |]
         let additional = [("triggered_at_time", String rfc3339Time)]
         pure (RouteActionResponseSuccess msg additional :: t)

       Right lastTime -> do
         let rfc3339Time = showRFC3339DateTime lastTime

         srcLogDebug [qms|
           Couldn't trigger {uncapitalizedActionTitle} manually because another
           {uncapitalizedActionTitle} is still in progress since {rfc3339Time}.
         |]

         throwError err503
           { errHeaders = pure $
               (hContentType, renderHeader $ contentType (Proxy :: Proxy JSON))

           , errBody =
               let
                 additional = [("last_trigger_time", String rfc3339Time)]

                 msg = [qms|
                   Cannot run {uncapitalizedActionTitle} because another
                   {uncapitalizedActionTitle} is still in progress.
                 |]
               in
                 encode (RouteActionResponseError msg additional :: t)
           }


srcLogDebug, srcLogError :: MonadLoggerBus m => Text -> m ()
srcLogDebug = LoggerBus.logDebugS logSrc
srcLogError = LoggerBus.logErrorS logSrc

logSrc :: LogSource
logSrc = "Server"
