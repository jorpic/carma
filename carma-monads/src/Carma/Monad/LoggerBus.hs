{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE QuasiQuotes #-}

module Carma.Monad.LoggerBus
     ( module Carma.Monad.LoggerBus.Class
     , genericMVarLog
     , genericMVarReadLog
     , genericTQueueLog
     , genericTQueueReadLog
     ) where

import qualified Data.Text as T
import           Text.InterpolatedString.QM

import           Control.Monad
import           Control.Monad.Logger (LogSource)
import           Control.Concurrent.STM.TQueue

import           Carma.Monad.STM
import           Carma.Monad.MVar
import           Carma.Monad.Clock
import           Carma.Monad.Thread
import           Carma.Monad.LoggerBus.Types
import           Carma.Monad.LoggerBus.Class
import           Carma.Monad.LoggerBus.Helpers


-- | Generic implementation of log function
--   from @MonadLoggerBus@ based on @MVar@.
--
-- Could be used to implement @logDebug@, @logInfo@, @logWarn@ and @logError@.
genericMVarLog
  :: (MonadMVar m, MonadClock m, MonadThread m)
  => LogSource
  -> LogMessageType
  -> MVar LogMessage
  -> T.Text
  -> m ()

genericMVarLog src logMsgType loggerBus' msg = do
  !utc <- getCurrentTime
  let !logMsg = LogMessage src logMsgType [qm| [{formatTime utc} UTC] {msg} |]

  -- Forking for non-blocking writing to @MVar@
  void $ fork $ putMVar loggerBus' logMsg


-- | Generic implementation of @readLog@
--   from @MonadLoggerBus@ based on @MVar@.
genericMVarReadLog :: MonadMVar m => MVar LogMessage -> m LogMessage
genericMVarReadLog = takeMVar


-- | Generic implementation of log function
--   from @MonadLoggerBus@ based on __STM__ @TQueue@.
--
-- Could be used to implement @logDebug@, @logInfo@, @logWarn@ and @logError@.
genericTQueueLog
  :: (MonadSTM m, MonadClock m)
  => LogSource
  -> LogMessageType
  -> TQueue LogMessage
  -> T.Text
  -> m ()

genericTQueueLog src logMsgType loggerBus' msg = do
  !utc <- getCurrentTime
  let !logMsg = LogMessage src logMsgType [qm| [{formatTime utc} UTC] {msg} |]
  atomically $ writeTQueue loggerBus' logMsg


-- | Generic implementation of @readLog@
--   from @MonadLoggerBus@ based on __STM__ @TQueue@.
genericTQueueReadLog :: MonadSTM m => TQueue LogMessage -> m LogMessage
genericTQueueReadLog = atomically . readTQueue
