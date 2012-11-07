
module AppHandlers.Util where


import Data.Text (Text)
import Data.Map (Map)
import qualified Data.Map as Map

import Data.Aeson as Aeson
import Data.Time
import Control.Concurrent.STM

import Snap
import Snap.Snaplet
import Snap.Snaplet.Auth

import Application
import Util


------------------------------------------------------------------------------
-- | Utility functions
writeJSON :: Aeson.ToJSON v => v -> AppHandler ()
writeJSON v = do
  modifyResponse $ setContentType "application/json"
  writeLBS $ Aeson.encode v

getJSONBody :: Aeson.FromJSON v => AppHandler v
getJSONBody = Util.readJSONfromLBS <$> readRequestBody 4096


addToLoggedUsers :: AuthUser -> AppHandler (Map Text (UTCTime,AuthUser))
addToLoggedUsers u = do
  logTVar <- gets loggedUsers
  logdUsers <- liftIO $ readTVarIO logTVar
  now <- liftIO getCurrentTime
  let logdUsers' = Map.insert (userLogin u) (now,u)
        -- filter out inactive users
        $ Map.filter ((>addUTCTime (-90*60) now).fst) logdUsers
  liftIO $ atomically $ writeTVar logTVar logdUsers'
  return logdUsers'


rmFromLoggedUsers :: AuthUser -> AppHandler ()
rmFromLoggedUsers u = do
  logdUsrs <- gets loggedUsers
  liftIO $ atomically $ modifyTVar' logdUsrs
         $ Map.delete $ userLogin u

