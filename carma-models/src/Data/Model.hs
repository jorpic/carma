{-# LANGUAGE ScopedTypeVariables #-}

module Data.Model
  ( Ident(..), IdentI, IdentT
  , Model(..)
  , NoParent
  , ModelInfo(..), mkModelInfo
  , Field(..), F, PK
  , FOpt
  , FieldDesc(..)
  , fieldName
  -- from Data.Model.View.Types
  , ModelView(..)
  ) where


import Control.Applicative
import Data.Maybe (fromJust)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.HashMap.Strict as HashMap
import Data.Aeson.Types as Aeson

import Database.PostgreSQL.Simple.FromRow   (RowParser,field)
import Database.PostgreSQL.Simple.FromField (FromField(..))
import Database.PostgreSQL.Simple.ToField   (ToField(..))
import Data.Dynamic
import GHC.TypeLits

import Data.Model.Types
import Data.Model.View.Types hiding (modelName)
import Data.Model.CoffeeType


mkModelInfo
  :: forall m ctr pkTy pkNm pkDesc
  . (Model m, Model (Parent m), GetModelFields m ctr, SingI pkNm)
  => ctr -> (m -> F (Ident pkTy m) pkNm pkDesc)
  -> ModelInfo m
mkModelInfo ctr pk =
  let parentFlds
        = if typeOf (undefined :: Parent m) == typeOf (undefined :: NoParent)
          then []
          else modelFields (modelInfo :: ModelInfo (Parent m))
      modelFlds
        = parentFlds
        ++ unWrap (getModelFields ctr :: [FieldDesc] :@ m)
  in ModelInfo
    { modelName      = T.pack $ show $ typeOf (undefined :: m)
    , tableName      = T.pack $ fromSing (sing :: Sing (TableName m))
    , primKeyName    = fieldName pk
    , modelFields    = modelFlds
    , modelFieldsMap = HashMap.fromList [(fd_name f, f) | f <- modelFlds]
    }


class (SingI (TableName m), Typeable m, Typeable (Parent m)) => Model m where
  type TableName m :: Symbol

  type Parent m
  type Parent m = NoParent

  modelInfo :: ModelInfo m
  modelView :: Text -> ModelView m


instance (Model m, Show t) => Show (Ident t m) where
  show (Ident x :: Ident t m) = "Ident " ++ modelName ++ " " ++ show x
    where
      modelName = show $ typeOf (undefined :: m)


data NoParent deriving Typeable
instance Model NoParent where
  type TableName NoParent = "(undefined)"
  type Parent NoParent = NoParent
  modelInfo = error "ModelInfo NoParent"
  modelView = error "ModelView NoParent"


data FOpt (name :: Symbol) (desc :: Symbol) = FOpt
data Field typ opt = Field
type F t n d = Field t (FOpt n d)
type PK t m  = Field (Ident t m) (FOpt "id" "object id")


fieldName :: SingI name => (model -> Field typ (FOpt name desc)) -> Text
fieldName (_ :: model -> Field typ (FOpt name desc))
  = T.pack $ fromSing (sing :: Sing name)


class GetModelFields m ctr where
  getModelFields :: ctr -> Wrap m [FieldDesc]

instance
    (GetModelFields m ctr, SingI nm, SingI desc, CoffeeType t
    ,FromJSON t, ToJSON t, FromField t, ToField t, Typeable t)
    => GetModelFields m (Field t (FOpt nm desc) -> ctr)
  where
    getModelFields f = Wrap
      $ fd
      : unWrap (getModelFields (f Field) :: [FieldDesc] :@ m)
      where
        fd = FieldDesc
          {fd_name      = T.pack $ fromSing (sing :: Sing nm)
          ,fd_desc      = T.pack $ fromSing (sing :: Sing desc)
          ,fd_type      = typeOf   (undefined :: t)
          ,fd_parseJSON = \v -> toDyn <$> (parseJSON v :: Parser t)
          ,fd_toJSON    = \d -> toJSON  (fromJust $ fromDynamic d :: t)
          ,fd_fromField = toDyn <$> (field :: RowParser t)
          ,fd_toField   = \d -> toField (fromJust $ fromDynamic d :: t)
          ,fd_coffeeType = unWrap (coffeeType :: Wrap t Text)
          }

instance GetModelFields m m where
  getModelFields _ = Wrap []
