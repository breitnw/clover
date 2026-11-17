{-# LANGUAGE AllowAmbiguousTypes #-}
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
  currentStatus,
  currentArtwork,
  sendCommand,
) where

import Effectful
import Effectful.Renderer
import Effectful.TH

import Effectful.MusicPlayer.Types

-- | Interface implemented by the music player backend.
--
-- Implementors of this interface must not be blocking.
data PlayMusicAsync a :: Effect where
  -- | Get the currently playing song.
  --
  -- If there is no song currently playing, returns Nothing.
  CurrentSong :: PlayMusicAsync a m (Maybe Song)
  -- | Get the current player status.
  CurrentStatus :: PlayMusicAsync a m PlayerStatus
  -- | Get the artwork for the current song.
  --
  -- If there is artwork present for the current song, returns a texture
  -- corresponding with that artwork.
  --
  -- If the newest artwork has not loaded yet, this function may return the
  -- previous artwork (or Nothing if none was present). This enables seamless
  -- transitions between songs in an album, but may cause wonky behavior if
  -- loading is slow.
  CurrentArtwork :: PlayMusicAsync a m (Maybe (Texture a))
  -- | Send a command to control the backend
  SendCommand :: Command -> PlayMusicAsync a m ()

makeEffect ''PlayMusicAsync
