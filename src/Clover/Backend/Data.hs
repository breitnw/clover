{- |
Module      : Clover.Backend.Data
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Data structures accepted and returned by the music player backend.
-}
module Clover.Backend.Data (
  Track (..),
  Command (..),
) where

data Track a = Song
  { title :: String
  , artist :: String
  , album :: String
  , trackID :: a
  }
  deriving (Show)

data Command = PlayPause | Next | Prev
