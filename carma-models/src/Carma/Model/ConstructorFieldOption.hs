module Carma.Model.ConstructorFieldOption where

import Data.Text
import Data.Typeable
import Data.Model
import Data.Model.View as View
import Carma.Model.Search (searchView, one)
import Carma.Model.Program (Program)
import Carma.Model.CtrModel  (CtrModel)


data ConstructorFieldOption = ConstructorFieldOption
  {ident    :: PK Int ConstructorFieldOption ""
  ,model    :: F (IdentI CtrModel)
                       "model"    "Модель, к которой относится поле"
  ,program  :: F (IdentI Program)
                       "program"  "Программа"
  ,ord      :: F Int   "ord"      "Порядок сортировки"
  ,field    :: F Text  "field"    "Внутреннее название поля"
  ,label    :: F Text  "label"    "Подпись к полю"
  ,info     :: F Text  "info"     "Текст для всплывающей подсказки"
  ,required :: F Bool  "required" "Обязательное поле"
  ,r        :: F Bool  "r"        "Доступно для чтения"
  ,w        :: F Bool  "w"        "Доступно для записи"
  }
  deriving Typeable


instance Model ConstructorFieldOption where
  type TableName ConstructorFieldOption = "ConstructorFieldOption"
  modelInfo = mkModelInfo ConstructorFieldOption ident
  modelView = \case
    "parents" -> Just
      $ (searchView
        [("program", one program)
        ,("model",   one model)
        ])
        {mv_modelName = "ConstructorFieldOption"}
    "" -> Just $ modifyView defaultView
      [readonly model,   View.required model
      ,readonly program, View.required program
      ,readonly field,   View.required field
      ,View.required ord
      ,View.required label
      ,textarea info
      ]
    _  -> Nothing
