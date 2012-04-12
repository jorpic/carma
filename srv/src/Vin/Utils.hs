{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleInstances #-}

module Vin.Utils where

import           Control.Applicative
import           Control.Exception (Exception,SomeException, try)
import           Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B
import qualified Data.Map as M
import           System.IO (stderr)

import           Control.Monad.IO.Class (liftIO)
import           Data.Text (Text)
import qualified Data.Text.Encoding as T
import           Data.Conduit
import           Data.Conduit.Binary
import qualified Data.Conduit.List as CL
import           Data.CSV.Conduit  hiding (MapRow, Row)
import           Database.Redis as R

import           Data.Xlsx.Parser


type Row = M.Map ByteString ByteString


redisSetVin :: R.Connection -> Row -> IO ()
redisSetVin c val
  = runRedis c
  $ mapM_ (\k -> redisSetWithKey' (mkKey k) val) vins
  where
    -- Внезапно оказалось, что у машины может быть два VINа.
    -- В качестве быстрого решения, пусть записи о машине дублируются.
    vins = B.words $ val M.! "vin"
    mkKey k = B.concat ["vin:", k]


redisSetWithKey' :: ByteString -> Row -> Redis ()
redisSetWithKey' key val = do
  res <- hmset key $ M.toList val
  case res of
    Left err -> liftIO $ print err
    _ -> return ()


loadXlsxFile store fInput fError keyMap = do
    x <- xlsx fInput
    try $ runResourceT $ sheetRows x 0
              $= CL.map encode
              $= CL.map (remap keyMap)
              $= storeCorrect store
              -- $= CL.map recodeToCP1251
              $$ writeIncorrect fError


storeCorrect :: MonadResource m
             => (R.Connection -> Row -> IO ())
             -> Conduit (Either Row Row) m Row
storeCorrect store = conduitIO
    (R.connect R.defaultConnectInfo)
    (\conn -> runRedis conn quit >> return ())
    (\conn row ->
         case row of
           Right r -> do
                        liftIO $ store conn r
                        return $ IOProducing []
           Left r  -> return $ IOProducing [r]
    )
    (const $ return [])


writeIncorrect :: MonadResource m => FilePath -> Sink Row m (Maybe FilePath)
writeIncorrect fp = do
    res <- CL.peek
    fp' <- writeRows fp
    return $ maybe Nothing (const $ Just fp') res


writeRows :: MonadResource m => FilePath -> Sink Row m FilePath
writeRows fp
    =  fromCSV defCSVSettings
    =$ sinkFile fp >> return fp


encode :: MapRow -> Row
encode m = M.map T.encodeUtf8 m'
  where
    m' = M.mapKeys T.encodeUtf8 m


remap :: [Record] -> Row -> Either Row Row
remap rs row =
    case getErrors row' of
      Left  es  -> Left $ M.insert "Error" (B.unwords es) row
      Right res -> Right res
  where
    row' = remap' rs row


remap' :: [Record] -> Row -> [(ByteString, Either ByteString ByteString)]
remap' rs row = foldl f [] rs
  where
    f res record =
        let k   = rKey record
            f   = rFind record
            val = f row
        in (k, val) : res


getErrors :: [(ByteString, Either ByteString ByteString)]
          -> Either [ByteString] Row
getErrors row = M.fromList <$> foldl f (Right []) row
  where
    f err@(Left res) (k, val) =
        case val of
          Right s -> err
          Left  e -> Left (e : res)
    f (Right res) (k, val) =
        case val of
          Right s -> Right $ (k, s) : res
          Left  e -> Left [e]


showMap :: Row -> ByteString
showMap = B.unlines . map showKV . M.toList
    where
      showKV (k,v) = B.concat ["\t", k, ": ", v]


data Record = Record
    { rKey  :: ByteString
    , rFind :: Row -> Either ByteString ByteString
    }


mkRecord (k, f) = Record k f
