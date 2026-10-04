{- |
Module      : Clover.Shared
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Types for shared state between Music and UI threads.
-}
module Clover.Shared (
  PlayerState (..),
  PlayerMode (..),
) where

import Effectful.ImageLoader.Types
import Effectful.MusicPlayer.Types

data PlayerState = PlayerState
  { psSong :: Maybe Song
  -- ^ The current song playing.
  , psArtwork :: Maybe Image
  -- ^ Artwork for the current song.
  , psProgress :: Maybe Float
  -- ^ Float 0 to 1 representing progress through the song.
  , psMode :: PlayerMode
  -- ^ Playing, paused, or stopped?
  }

data PlayerMode = Playing | Paused | Stopped
