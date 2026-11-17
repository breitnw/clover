{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.MusicPlayer.Sync.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

MPD effect with blocking operations.
-}
module Effectful.MusicPlayer.Sync.Effect (
  PlayMusicSync (..),
  currentSong,
  currentStatus,
  loadArtwork,
  sendCommand,
) where

import Data.ByteString qualified as BS
import Effectful
import Effectful.TH

import Effectful.MusicPlayer.Types

-- | Interface implemented by the music player backend.
--
-- Implementors of this interface may be blocking. Scheduling should be handled
-- by the user of the effect.
data PlayMusicSync :: Effect where
  -- | Get the currently playing song.
  --
  -- If there is no song currently playing, returns Nothing.
  CurrentSong :: PlayMusicSync m (Maybe Song)
  -- | Get the current player status.
  CurrentStatus :: PlayMusicSync m PlayerStatus
  -- | Load a chunk of the artwork for the song specified by a song ID.
  --
  -- If the album art is ready for a given song, returns 'Ready'. If the album
  -- art is still loading, returns 'Waiting'. If there is no album art present,
  -- returns 'Nothing'
  LoadArtwork :: SongID -> PlayMusicSync m (Maybe (LoadStatus BS.ByteString))
  -- | Send a command to control the backend
  SendCommand :: Command -> PlayMusicSync m ()

makeEffect ''PlayMusicSync
