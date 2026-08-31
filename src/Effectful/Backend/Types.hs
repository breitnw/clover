{- |
Module      : Effectful.Backend.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Data definitions
-}
module Effectful.Backend.Types (
  SongID,
  Song (..),
  Command,
) where

import Data.Text (Text)

newtype SongID = SongID Text deriving (Show)

data Song = Song
  { title :: Maybe Text
  , artist :: Maybe Text
  , album :: Maybe Text
  , songID :: SongID
  }
  deriving (Show)

-- | Control command that can be sent to the music backend.
data Command = PlayPause | Next | Previous
