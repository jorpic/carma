{-# LANGUAGE OverloadedStrings #-}


module Site
  ( app
  ) where

import           Control.Applicative
import           Control.Monad.Trans
import           Control.Monad.State
import           Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString.Lazy as L
import qualified Data.Text as T
import           Data.Lens.Common
import qualified Data.Map as M
import           Data.List
import           Data.Maybe (catMaybes)
import           Data.Either (rights)
import           Snap.Core
import           Snap.Snaplet
import           Snap.Util.FileServe
import           Snap.Snaplet.RedisDB
import           Data.Aeson as A
import           Data.Aeson.Types as A
import           Database.Redis
import           Application


searchCase = do
  let response = A.encode $ object
        ["iTotalRecords" .= (0::Int)
        ,"iTotalDisplayRecords" .= (0::Int)
        ,"aaData" .= A.toJSON ([]::[T.Text])
        ]
  modifyResponse $ setContentType "application/json"
  writeLBS response


searchDealer = search "dealer"
  ["name","city","program","salesAddr", "salesPhone"]
  [("name","sSearch_0")
    ,("city","sSearch_1")
    ,("program","sSearch_2")]


searchContractor = search "partner"
  ["companyName","cityRu","contactPerson","contactPhone","serviceRu"]
  [("companyName","sSearch_0")
    ,("contactPerson","sSearch_2")
    ,("contactPhone","sSearch_3")]


search keyPrefix outFields searchFields = do
  let (attrs,pats) = unzip searchFields

  ps <- rqParams <$> getRequest
  let si = map (head . (M.!) ps) pats
  let displayStart = head $ (M.!) ps "iDisplayStart"

  (vals,total) <- runRedisDB redisDB $ do
    let searchKeys = catMaybes $ zipWith
          (\k s -> if B.null s
            then Nothing
            else Just $ B.concat [keyPrefix,":",k,":*",s,"*"])
          attrs si

    matchingKeys <- if null searchKeys
        then (:[]). fromRight <$> keys (B.concat [keyPrefix,":*"])
        else rights <$> mapM keys searchKeys
    
    keys' <- foldl1' intersect . map (foldl' union [])
          <$> forM matchingKeys
            ((rights <$>) . mapM (\k ->lrange k 0 (-1)))

    vals  <- (catMaybes . fromRight) <$>  mget (take 100 keys')
    return (vals, length keys')

  let res = catMaybes $ flip map
        (catMaybes $ map (A.decode . L.fromChunks .(:[])) vals)
        $ A.parseMaybe (\o -> mapM (o .:) outFields)
        :: [[A.Value]]

  let response = A.encode $ object
        ["iTotalRecords" .= total
        ,"iTotalDisplayRecords" .= (100::Int)
        ,"aaData" .= toJSON res
        ]
  modifyResponse $ setContentType "application/json"
  writeLBS response


fromRight = either (const []) id


newCase :: Handler App App ()
newCase = do
  rq <- getRequestBody
  case A.decode rq of
    Nothing -> writeLBS "error" -- FIXME: return some http status != 200
    Just json -> do
        i <- runRedisDB redisDB $ do
          Right i <- incr "case:lastId"
          let key = B.concat ["case:", B.pack $ show i]
          set key $ B.concat $ L.toChunks $ A.encode (json :: Value)
          return i
        modifyResponse $ setContentType "application/json"
        writeLBS $ A.encode i

getCase = undefined

------------------------------------------------------------------------------
-- | The application's routes.
routes :: [(ByteString, Handler App App ())]
routes = [("/s", serveDirectory "resources")
         ,("/",  serveFile "resources/index.html")
         ,("/api/search_case", method GET searchCase)
         ,("/api/search_dealer", method GET searchDealer)
         ,("/api/search_contractor", method GET searchContractor)
         ,("/api/case", method POST newCase)
         ,("/api/case/:id", method GET getCase)
         ]

------------------------------------------------------------------------------
-- | The application initializer.
app :: SnapletInit App App
app = makeSnaplet "app" "" Nothing $ do
    addRoutes routes
    r <- nestSnaplet "" redisDB $ redisDBInit defaultConnectInfo
    return $ App r


