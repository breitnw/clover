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
import TextShow qualified as T

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
newtype SongID = SongID T.Text deriving (Show, Eq)

instance T.TextShow SongID where
  showb (SongID sid) = T.showb "SongID " <> T.showb sid

-- | Data representing a song.
data Song = Song
  { sgTitle :: Maybe T.Text
  , sgArtist :: Maybe T.Text
  , sgAlbum :: Maybe T.Text
  , sgDurationMillis :: Maybe Int
  , sgID :: SongID
  -- TODO should this include albumart?
  -- TODO or maybe some sort of albumart ID
  -- > probably not, haskell is GC'd so might as well store a ref
  -- > just need to be careful to use the same bytestring if albumart is the same
  }

instance T.TextShow Song where
  showb
    ( Song
        { sgTitle = title
        , sgArtist = artist
        , sgAlbum = album
        , sgDurationMillis = millis
        , sgID = sid
        }
      ) =
      T.showb "Song { title: "
        <> T.showb title
        <> T.showb ", artist: "
        <> T.showb artist
        <> T.showb ", album: "
        <> T.showb album
        <> T.showb ", millis: "
        <> T.showb millis
        <> T.showb ", id: "
        <> T.showb sid
        <> T.showb "}"

-- | Control command that can be sent to the music backend.
data Command = Play | Pause | Resume | Next | Previous
