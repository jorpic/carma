{-# LANGUAGE DeriveDataTypeable #-}

-- To add docs for every type or function defined in the module.
{-# OPTIONS_HADDOCK ignore-exports #-}

-- | Additional types for VIN synchronizer.
module Carma.EraGlonass.VinSynchronizer.Types
     ( EGRequestException (..)

     , OneOrTwoNonEmptyLists (..)
     , getFirstNonEmptyList
     , getSecondNonEmptyList
     ) where

import           Data.Typeable
import           Data.List.NonEmpty (NonEmpty)
import           Data.Aeson

import           Control.Exception

import           Servant.Client (ServantError)

import           Carma.EraGlonass.Types.EGCheckVinRequest (EGCheckVinRequest)


data EGRequestException
   = EGCheckVinRequestIsFailed ServantError EGCheckVinRequest
     -- ^ When request to EG is failed
   | EGCheckVinResponseIsFailed String Value
     -- ^ When for instance parsing response from EG is failed
     deriving (Show, Eq, Typeable)

instance Exception EGRequestException


-- | Helper type for VINs unmarking.
data OneOrTwoNonEmptyLists first second
   = FirstNonEmptyList  (NonEmpty first)
   | SecondNonEmptyList (NonEmpty second)
   | BothNonEmptyLists  (NonEmpty first) (NonEmpty second)
     deriving (Show, Eq)


getFirstNonEmptyList :: OneOrTwoNonEmptyLists a b -> Maybe (NonEmpty a)
getFirstNonEmptyList (FirstNonEmptyList  x  ) = Just x
getFirstNonEmptyList (SecondNonEmptyList _  ) = Nothing
getFirstNonEmptyList (BothNonEmptyLists  x _) = Just x

getSecondNonEmptyList :: OneOrTwoNonEmptyLists a b -> Maybe (NonEmpty b)
getSecondNonEmptyList (FirstNonEmptyList  _  ) = Nothing
getSecondNonEmptyList (SecondNonEmptyList x  ) = Just x
getSecondNonEmptyList (BothNonEmptyLists  _ x) = Just x
