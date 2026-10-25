{-# LANGUAGE DeriveFunctor #-}

{- |
Module      : Effectful.MusicPlayer.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Data definitions for MusicPlayer effect
-}
module Effectful.MusicPlayer.Types (
  Status (..),
  SongID (..),
  Song (..),
  Command (..),
  MusicPlayerError (..),
) where

import Data.Text qualified as T

-- | A resource is either being waited on or done
--
-- Basically just Maybe but with a better name.
data Status a = Waiting | Done a
  deriving (Functor, Show, Eq)

instance Applicative Status where
  pure = Done

  Done f <*> m = fmap f m
  Waiting <*> _m = Waiting

instance Monad Status where
  (Done x) >>= k = k x
  Waiting >>= _ = Waiting

data MusicPlayerError
  = Timeout

-- | Unique identifier of a song.
newtype SongID = SongID T.Text deriving (Show)

-- | Data representing a song.
data Song = Song
  { sgTitle :: Maybe T.Text
  , sgArtist :: Maybe T.Text
  , sgAlbum :: Maybe T.Text
  , sgDurationMillis :: Maybe Int
  , sgID :: SongID
  -- TODO should this include albumart?
  -- TODO or maybe some sort of albumart ID
  }
  deriving (Show)

-- | Control command that can be sent to the music backend.
data Command = Play | Pause | Resume | Next | Previous
