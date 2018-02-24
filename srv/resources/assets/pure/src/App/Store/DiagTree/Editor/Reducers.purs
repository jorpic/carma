module App.Store.DiagTree.Editor.Reducers
     ( DiagTreeEditorState
     , diagTreeEditorInitialState
     , diagTreeEditorReducer
     , FoundSlides
     ) where

import Prelude

import Data.Maybe (Maybe (..))
import Data.Map (Map)
import Data.Map as Map
import Data.Set (Set)
import Data.Set as Set
import Data.String (Pattern (Pattern), toLower, indexOf)
import Data.String.NonEmpty (toString)
import Data.Foldable (foldl)

import App.Store.DiagTree.Editor.Types
     ( DiagTreeSlides
     , DiagTreeSlideId
     , DiagTreeSlide (DiagTreeSlide)
     )

import App.Store.DiagTree.Editor.Actions
     ( DiagTreeEditorAction (..)
     , LoadSlidesFailureReason (..)
     )

import App.Store.DiagTree.Editor.TreeSearch.Reducers
     ( DiagTreeEditorTreeSearchState
     , diagTreeEditorTreeSearchInitialState
     , diagTreeEditorTreeSearchReducer
     )


type FoundSlides =
  { matchedSlides
      :: Set DiagTreeSlideId
      -- ^ Found slides (including parents of branches)

  , matchedPatterns
      :: Map DiagTreeSlideId { answer :: Maybe Int, question :: Maybe Int }
      -- ^ `Int` value is start position of matched pattern,
      --   for example search pattern is "bar baz" and if `answer` of a slide
      --   has value "foo bar baz bzz" then it would be `Just 4`.
      --   (search word length could be determinted from 'treeSearch' branch).
  }

type DiagTreeEditorState =
  { slides                    :: DiagTreeSlides
  , foundSlides               :: Maybe FoundSlides

  -- Selected slide with all parents in ascending order
  , selectedSlideBranch       :: Maybe (Array DiagTreeSlideId)

  , isSlidesLoaded            :: Boolean
  , isSlidesLoading           :: Boolean
  , isSlidesLoadingFailed     :: Boolean
  , isParsingSlidesDataFailed :: Boolean

  , treeSearch                :: DiagTreeEditorTreeSearchState
  }

diagTreeEditorInitialState :: DiagTreeEditorState
diagTreeEditorInitialState =
  { slides                    : Map.empty
  , selectedSlideBranch       : Nothing
  , foundSlides               : Nothing

  , isSlidesLoaded            : false
  , isSlidesLoading           : false
  , isSlidesLoadingFailed     : false
  , isParsingSlidesDataFailed : false

  , treeSearch                : diagTreeEditorTreeSearchInitialState
  }


diagTreeEditorReducer
  :: DiagTreeEditorState -> DiagTreeEditorAction -> Maybe DiagTreeEditorState

diagTreeEditorReducer state LoadSlidesRequest =
  Just state { slides                    = (Map.empty :: DiagTreeSlides)
             , selectedSlideBranch       = Nothing

             , isSlidesLoaded            = false
             , isSlidesLoading           = true
             , isSlidesLoadingFailed     = false
             , isParsingSlidesDataFailed = false
             }

diagTreeEditorReducer state (LoadSlidesSuccess { slides, rootSlide }) =
  Just state { slides              = slides
             , selectedSlideBranch = Just [rootSlide]
             , isSlidesLoaded      = true
             , isSlidesLoading     = false
             }

diagTreeEditorReducer state (LoadSlidesFailure LoadingSlidesFailed) =
  Just state { isSlidesLoading       = false
             , isSlidesLoadingFailed = true
             }

diagTreeEditorReducer state (LoadSlidesFailure ParsingSlidesDataFailed) =
  Just state { isSlidesLoading           = false
             , isSlidesLoadingFailed     = true
             , isParsingSlidesDataFailed = true
             }

diagTreeEditorReducer _ (SelectSlide []) = Nothing

diagTreeEditorReducer state (SelectSlide branch) =
  Just state { selectedSlideBranch = Just branch }

diagTreeEditorReducer state (TreeSearch subAction) =
  diagTreeEditorTreeSearchReducer state.treeSearch subAction
    <#> state { treeSearch = _ }
    <#> \s@{ slides, treeSearch: { searchQuery: q } } ->
          let f = toString >>> toLower >>> Pattern >>> search slides
           in s { foundSlides = q <#> f }

  where
    search slides query =
      let initial = { matchedSlides: Set.empty, matchedPatterns: Map.empty }
       in foldl (searchReduce query) initial slides

    searchReduce query acc (DiagTreeSlide x) =
      let
        rootMatch pos = Map.insert x.id { answer: Nothing, question: Just pos }
      in
        case query `indexOf` toLower x.header <#> rootMatch of
             Nothing -> acc
             Just f  -> acc { matchedPatterns = f acc.matchedPatterns }
