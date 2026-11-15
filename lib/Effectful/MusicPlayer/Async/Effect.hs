{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.MusicPlayer.Async.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.MusicPlayer.Async.Effect (
  PlayMusicAsync (..),
  currentSong,
  loadArtwork,
  sendCommand,
) where

import Data.ByteString qualified as BS
import Effectful
import Effectful.TH

import Effectful.MusicPlayer.Types

-- | Interface implemented by the music player backend.
--
-- Implementors of this interface must not be blocking.
data PlayMusicAsync :: Effect where
  -- | Get the currently playing song.
  --
  -- If there is no song currently playing, returns Nothing.
  CurrentSong :: PlayMusicAsync m (Maybe Song)
  -- | Load a chunk of the artwork for the song specified by a song ID.
  --
  -- If the album art is ready for a given song, returns 'Ready'. If the album
  -- art is still loading, returns 'Waiting'. If there is no album art present,
  -- returns 'Nothing'
  CurrentArtwork :: SongID -> PlayMusicAsync m (Maybe (Status BS.ByteString))
  -- | Send a command to control the backend
  SendCommand :: Command -> PlayMusicAsync m ()

makeEffect ''PlayMusicAsync
