{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TemplateHaskell #-}

-- TODO maybe move to a Shared directory

{- |
Module      : Effectful.MusicPlayer.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Data definitions for MusicPlayer effects
-}
module Effectful.MusicPlayer.Types (
  LoadStatus (..),
  SongID (..),
  Song (..),
  Command (..),
  PlayerState (..),
  SingleState (..),
  ConsumeState (..),
  PlayerStatus (..),
) where

import Data.Text qualified as T
import Effectful.Timer
import TextShow.TH qualified as T

-- | A resource is either being waited on or done
--
-- Basically just Maybe but with a better name.
data LoadStatus a = Waiting | Done a
  deriving (Functor, Show, Eq)

instance Applicative LoadStatus where
  pure = Done

  Done f <*> m = fmap f m
  Waiting <*> _m = Waiting

instance Monad LoadStatus where
  (Done x) >>= k = k x
  Waiting >>= _ = Waiting

-- | Unique identifier of a song.
newtype SongID = SongID T.Text deriving (Show, Eq)

T.deriveTextShow ''SongID

-- | Data representing a song.
data Song = Song
  { sgTitle :: Maybe T.Text
  , sgArtist :: Maybe T.Text
  , sgAlbum :: Maybe T.Text
  , sgDuration :: Maybe Float
  , sgID :: SongID
  -- TODO should this include albumart?
  -- TODO or maybe some sort of albumart ID
  -- > probably not, haskell is GC'd so might as well store a ref
  }

T.deriveTextShow ''Song

data PlayerState = Playing | Paused | Stopped

data SingleState = SingleOff | SingleOn | SingleOneshot | SingleUnavailable

data ConsumeState = ConsumeOff | ConsumeOn | ConsumeOneshot | ConsumeUnavailable

data PlayerStatus = PlayerStatus
  { psState :: PlayerState
  , psProgress :: Float
  , psRepeat :: Bool
  , psRandom :: Bool
  , psSingle :: SingleState
  , psConsume :: ConsumeState
  , psTimestamp :: POSIXTime
  -- TODO queue information from the state would be good as well
  }

T.deriveTextShow ''PlayerState
T.deriveTextShow ''SingleState
T.deriveTextShow ''ConsumeState

-- TODO can't for now since POSIXTime does not have TextShow
-- T.deriveTextShow ''PlayerStatus

-- | Control command that can be sent to the music backend.
data Command = Play | Pause | Resume | Next | Previous
