module Carma.Model.Service.DeliverCar where

import Data.Text
import Data.Typeable

import Data.Model
import Data.Model.View
import Carma.Model.LegacyTypes
import Carma.Model.Service (Service)


data DeliverCar = DeliverCar
  { ident :: PK Int DeliverCar ""
  , toAddress_address :: F PickerField "toAddress_address" "Куда везти"
  , toAddress_comment :: F (Maybe Text)"toAddress_comment" "Примечания"
  , toAddress_coords  :: F PickerField "toAddress_coords"  "Координаты"
  , toAddress_map     :: F MapField    "toAddress_map"     ""
  }
  deriving Typeable

instance Model DeliverCar where
  type TableName DeliverCar = "delivercartbl"
  type Parent DeliverCar = Service
  parentInfo = ExParent modelInfo
  modelInfo = mkModelInfo DeliverCar ident
  modelView v = case parentView v :: Maybe (ModelView DeliverCar) of
    Nothing -> Nothing
    Just mv -> Just
      $ modifyView (mv {mv_title = "Доставка ТС"})
      $ mapWidget toAddress_address toAddress_coords toAddress_map
