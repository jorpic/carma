{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ConstraintKinds #-}

module Carma.Monad.IORefWithCounter
     ( -- Constructor isn't exported.
       -- Only `MonadIORefWithCounter` allowed for manipulations
       -- to prevent human-factor mistakes.
       -- If you missed something for `IORef` please just implement it in
       -- `MonadIORefWithCounter` and do not forget to update a counter if you
       -- modify something.
       IORefWithCounter
     , MonadIORefWithCounter
     , newIORefWithCounter
     , readIORefWithCounter
     , readIORefWithCounter'
     , modifyIORefWithCounter'
     , atomicModifyIORefWithCounter'
     ) where

import           Data.IORef

import           Control.Monad.IO.Class (MonadIO, liftIO)

import           Carma.Utils


newtype IORefWithCounter a = IORefWithCounter (IORef (Integer, a))

type MonadIORefWithCounter m = MonadIO m


newIORefWithCounter :: MonadIORefWithCounter m => a -> m (IORefWithCounter a)
newIORefWithCounter x = liftIO $ newIORef (0, x) <&!> IORefWithCounter


{-# INLINE readIORefWithCounter #-}
readIORefWithCounter :: MonadIORefWithCounter m => IORefWithCounter a -> m a
readIORefWithCounter x = readIORefWithCounter' x <&!> snd

readIORefWithCounter' :: MonadIORefWithCounter m
                      => IORefWithCounter a -> m (Integer, a)
readIORefWithCounter' (IORefWithCounter r) = liftIO $ readIORef r


-- `Eq` is needed to check if something changed to increment the counter
modifyIORefWithCounter' :: (Eq a, MonadIORefWithCounter m)
                        => IORefWithCounter a -> (a -> a) -> m ()
modifyIORefWithCounter' (IORefWithCounter x) f =
  liftIO $ x `modifyIORef'`
    \(c, v) -> let v' = f v in (if v' /= v then succ c else c, v')


-- `Eq` is needed to check if something changed to increment the counter
atomicModifyIORefWithCounter' :: (Eq a, MonadIORefWithCounter m)
                              => IORefWithCounter a -> (a -> (a, b)) -> m b
atomicModifyIORefWithCounter' (IORefWithCounter x) f =
  liftIO $ x `atomicModifyIORef'`
    \(c, v) -> let (v', a) = f v in ((if v' /= v then succ c else c, v'), a)
