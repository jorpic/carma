{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}
module AppHandlers.CaseInfo
    where

import           Data.Aeson (ToJSON)
import qualified Data.Map as Map
import           Data.Map ((!))
import           Data.Maybe (fromMaybe)
import           Database.PostgreSQL.Simple.FromRow
import           Database.PostgreSQL.Simple.SqlQQ
import           GHC.Generics (Generic)
import           Snap.Snaplet
import           Snap.Snaplet.Auth
import           Snap.Snaplet.PostgresqlSimple
                 ( query
                 , In (..), Only (..)
                 )

import           Application
import           AppHandlers.Users
import           AppHandlers.Util
import qualified Carma.Model.ServiceStatus as SS
import           Data.Model

import           Types


casesLimit :: Int
casesLimit = 1000



data CaseInfo = CaseInfo
    { caseId :: Int
    , services :: Int
    , callDate :: String
    , typeOfService :: String
    , status :: String
    , accordTime :: String
    , makeModel :: String
    , breakdownPlace :: String
    , payType :: String
    } deriving (Show, Generic)

instance ToJSON CaseInfo

instance FromRow CaseInfo where
    fromRow = CaseInfo <$> field
                       <*> field
                       <*> field
                       <*> field
                       <*> field
                       <*> field
                       <*> field
                       <*> field
                       <*> field


-- | Handle get latest cases
handleApiGetLatestCases :: LatestCases -> AppHandler ()
handleApiGetLatestCases caseType = checkAuthCasePartner $ do
  user <- fromMaybe (error "No current user") <$> with auth currentUser
  let UserId uid = fromMaybe (error "no uid") $ userId user
  let statuses = case caseType of
                     Current -> [SS.ordered, SS.delayed, SS.inProgress]
                     Closing -> [SS.ok]

  rows :: [CaseInfo] <- query [sql|
    SELECT
        servicetbl.parentid
      , 0 as services
      , date_trunc('second', createTime::timestamp)::text as cTime
      , st.label
      , ss.label
      , date_trunc('second', times_expectedservicestart::timestamp)::text
      , make.label || ' / ' || model.label
       , casetbl.caseaddress_address
      , pt.label
    FROM servicetbl
    LEFT OUTER JOIN "ServiceType" st ON st.id = type
    LEFT OUTER JOIN "ServiceStatus" ss ON ss.id = status
    LEFT OUTER JOIN "PaymentType" pt ON pt.id = paytype
    LEFT OUTER JOIN casetbl ON casetbl.id = parentid
    LEFT OUTER JOIN "CarMake" make ON make.id = casetbl.car_make
    LEFT OUTER JOIN "CarModel" model ON model.id = casetbl.car_model
    LEFT OUTER JOIN "CasePartner" cp
                 ON cp.partner = servicetbl.contractor_partnerid
    WHERE (servicetbl.status IN ?)
      AND (createTime IS NOT NULL)
      AND cp.uid = ?
    ORDER BY cTime DESC
    LIMIT ?
  |] ( In $ map (\(Ident i) -> i)  statuses :: In [Int]
     , uid
     , casesLimit
     )

  counters :: Map.Map Int Int <- fmap Map.fromList <$> query [sql|
    SELECT parentid, count(*)
    FROM servicetbl
    WHERE parentid in ?
    GROUP BY parentid
  |] $ Only $ In $ map caseId rows

  writeJSON $ map (\m -> m { services = counters ! caseId m} :: CaseInfo) rows