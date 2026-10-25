{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.MusicPlayer.Blocking.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

MPD effect with blocking operations.
-}
module Effectful.MusicPlayer.Blocking.Effect (
  PlayMusic (..),
  currentSong,
  loadArtwork,
  sendCommand,
) where

-- TODO we don't really need a bytestring for LoadArtwork, just hand off the raw
-- pointer? saves a huge memory copy, but costs some manual memory management

import Data.ByteString qualified as BS
import Effectful
import Effectful.TH

import Effectful.MusicPlayer.Types

-- | Interface implemented by the music player backend.
--
-- Implementors of this interface may be blocking. Scheduling should be handled
-- by the user of the effect.
data PlayMusic :: Effect where
  -- | Get the currently playing song.
  --
  -- If there is no song currently playing, returns Nothing.
  CurrentSong :: PlayMusic m (Maybe Song)
  -- | Load a chunk of the artwork for the song specified by a song ID.
  --
  -- If the album art is ready or not present for the requested song, returns
  -- 'Ready'. If the album art is still loading, returns 'Waiting'.
  LoadArtwork :: SongID -> PlayMusic m (Status (Maybe BS.ByteString))
  -- | Send a command to control the backend
  SendCommand :: Command -> PlayMusic m ()

makeEffect ''PlayMusic
