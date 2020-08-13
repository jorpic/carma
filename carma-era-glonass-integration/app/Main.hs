{-# LANGUAGE BangPatterns, LambdaCase, RecordWildCards, QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables, FlexibleContexts #-}

-- | Production server implementation.
module Main (main) where

import           Data.Pool (Pool)
import           Text.InterpolatedString.QM

import           Control.Monad.Reader

import           Database.Persist.Postgresql

import           Carma.Monad.LoggerBus.Class
import           Carma.Model.Usermeta.Persistent (admin)
import           Carma.EraGlonass.Types.AppContext
import           Carma.EraGlonass.App
import           Carma.EraGlonass.Instances ()
import           Carma.EraGlonass.Logger.LoggerForward (runLoggerForward)


main :: IO ()
main = app ProductionAppMode $ \AppConfig {..} withDbConnection -> do
  logInfo [qms| Creating PostgreSQL connection pool
                (pool size is: {pgPoolSize pgConf},
                 request timeout: {dbRequestTimeout} seconds)... |]

  loggerBus' <- ask
  !(pgPool :: Pool SqlBackend) <- liftIO $
    createPostgresqlPool (pgConnStr pgConf) (pgPoolSize pgConf)
      `runLoggerForward` loggerBus'

  -- Request at start to check if it's connected (DB connection is lazy).
  liftIO (get admin `runSqlPool` pgPool)
    >>= \case Just _  -> pure ()
              Nothing -> fail "Initial test database request is failed!"

  withDbConnection $ DBConnectionPool pgPool
