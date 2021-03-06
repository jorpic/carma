module Component.DiagTree.Editor.SlideEditor.Action
     ( diagTreeEditorSlideEditorAction
     ) where

import Prelude hiding (div)

import Data.Maybe (Maybe (..))

import Effect (Effect)

import React (ReactClass, component, getProps, createLeafElement)
import React.DOM (text, div, div', label)
import React.DOM.Props (className)

import Utils ((<.>), unfoldrBoundedEnum)
import Component.Generic.DropDownSelect (dropDownSelect)
import App.Store (Store)
import App.Store.DiagTree.Editor.Types (DiagTreeSlideAction)


type Props state action =
   { store      :: Store state action
   , isDisabled :: Boolean
   , action     :: Maybe DiagTreeSlideAction
   , onSelected :: Maybe DiagTreeSlideAction -> Effect Unit
   }

diagTreeEditorSlideEditorActionRender
  :: forall state action. ReactClass (Props state action)

diagTreeEditorSlideEditorActionRender = defineComponent $
  \ { store, isDisabled, action, onSelected } ->

  [ label [className "control-label"] [text "Рекомендация"]

  , div' $ pure $
      dropDownSelectEl
        { store
        , isDisabled
        , variants
        , selected: action
        , variantView: (show :: DiagTreeSlideAction -> String)
        , onSelected: Just onSelected
        , placeholder: Just "Что делать?"
        , notSelectedTitle: Just "(не выбрано)"
        }
  ]

  where
    name = "DiagTreeEditorSlideEditorAction"
    classSfx s = name <> "--" <> s
    wrapper = div [className $ "form-group" <.> name]
    variants = (unfoldrBoundedEnum :: Array DiagTreeSlideAction)
    dropDownSelectEl = createLeafElement dropDownSelect

    defineComponent renderFn = component name \this -> pure
      { render: map wrapper $ renderFn <$> getProps this
      }


diagTreeEditorSlideEditorAction
  :: forall state action. ReactClass (Props state action)

diagTreeEditorSlideEditorAction = diagTreeEditorSlideEditorActionRender
