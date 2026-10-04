{- |
Module      : Effectful.MusicPlayer.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Data definitions
-}
module Effectful.MusicPlayer.Types (
  SongID (..),
  Song (..),
  Command (..),
) where

import Data.Text qualified as T

newtype SongID = SongID T.Text deriving (Show)

data Song = Song
  { title :: Maybe T.Text
  , artist :: Maybe T.Text
  , album :: Maybe T.Text
  , songID :: SongID
  }
  deriving (Show)

-- | Control command that can be sent to the music backend.
data Command = PlayPause | Next | Previous
