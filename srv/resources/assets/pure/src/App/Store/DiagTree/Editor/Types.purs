module App.Store.DiagTree.Editor.Types
     ( DiagTreeSlideId
     , DiagTreeSlides
     , DiagTreeSlide (DiagTreeSlide)
     , DiagTreeSlideResource
     , DiagTreeSlideAttachment (..)
     , DiagTreeSlideAction (..)
     , DiagTreeSlideAnswer
     ) where

import Prelude

import Data.Map (Map)
import Data.Maybe (Maybe)
import Data.DateTime (DateTime)
import Data.Generic (class Generic)
import Data.Enum (class Enum, class BoundedEnum)

import Data.Generic.Rep as GRep
import Data.Generic.Rep.Bounded as GRepBounded
import Data.Generic.Rep.Enum as GRepEnum

import App.Store.DiagTree.Editor.Handlers.SharedUtils.BackendAttachment
     ( BackendAttachmentMediaType
     )


type DiagTreeSlideId = Int
type DiagTreeSlides  = Map DiagTreeSlideId DiagTreeSlide


data DiagTreeSlideAttachment
  = Legacy String
  -- ^ This is legacy field with inlined uploaded file as a string of base64
  --   (this is only for old uploads).
  --   TODO Get rid of this field, write some migration, and then type
  --   `DiagTreeSlideAttachment` must be removed too, only record from
  --   `Modern` must be type of `attachment` field of `DiagTreeSlideResource`.

  | Modern { id        :: Int
           , hash      :: String
           , filename  :: String
           , mediaType :: BackendAttachmentMediaType
           }

instance eqDiagTreeSlideAttachment :: Eq DiagTreeSlideAttachment
  where

  eq (Modern a) (Modern b) =
    a.id        == b.id       &&
    a.hash      == b.hash     &&
    a.filename  == b.filename &&
    a.mediaType == b.mediaType

  eq (Legacy a) (Legacy b) = a == b
  eq _ _ = false

type DiagTreeSlideResource =
  { text       :: String
  , attachment :: DiagTreeSlideAttachment
  }


data DiagTreeSlideAction
  = Towage
  | BikeTowage
  | Tech
  | Consultation

derive instance genericDiagTreeSlideAction :: Generic DiagTreeSlideAction
derive instance eqDiagTreeSlideAction      :: Eq      DiagTreeSlideAction
derive instance ordDiagTreeSlideAction     :: Ord     DiagTreeSlideAction

instance showDiagTreeSlideAction :: Show DiagTreeSlideAction where
  show Towage       = "Создать Эвакуацию"
  show BikeTowage   = "Создать Мотоэвакуация"
  show Tech         = "Создать Техпомощь"
  show Consultation = "Создать Консультацию"

derive instance genericRepDiagTreeSlideAction ::
  GRep.Generic DiagTreeSlideAction _

instance genericRepBoundedDiagTreeSlideAction :: Bounded DiagTreeSlideAction
  where
  bottom = GRepBounded.genericBottom
  top    = GRepBounded.genericTop

instance genericRepEnumDiagTreeSlideAction :: Enum DiagTreeSlideAction where
  pred = GRepEnum.genericPred
  succ = GRepEnum.genericSucc

instance genericRepBoundedEnumDiagTreeSlideAction ::
  BoundedEnum DiagTreeSlideAction
  where
  cardinality = GRepEnum.genericCardinality
  toEnum      = GRepEnum.genericToEnum
  fromEnum    = GRepEnum.genericFromEnum


type DiagTreeSlideAnswer =
  { nextSlide  :: DiagTreeSlide

  , header     :: String
  -- ^ Also known as "answer" of a slide
  --   (a user's answer that leads to this slide - `nextSlide`).

  , text       :: String
  , attachment :: Maybe DiagTreeSlideAttachment
  }


-- `newtype` is required here to allow recursive types
newtype DiagTreeSlide
  = DiagTreeSlide
  { id        :: DiagTreeSlideId
  , isRoot    :: Boolean
  , ctime     :: DateTime
  , header    :: String -- ^ Also known as "question" of a slide
  , body      :: String
  , resources :: Array DiagTreeSlideResource
  , action    :: Maybe DiagTreeSlideAction

  , answers   :: Map DiagTreeSlideId DiagTreeSlideAnswer
  -- ^ You could read "answers" here as "children slides"
  }
