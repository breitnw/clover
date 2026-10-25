{-# LANGUAGE TemplateHaskell #-}

{-

{- |
Module      : Effectful.MusicPlayer.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

MPD effect with continuous operation.
-}
module Effectful.MusicPlayer.Continuous.Effect (
  PlayMusic (..),
  currentSong,
  getSong,
  getArtwork,
  sendCommand,
) where

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
  CurrentSong :: PlayMusic m (Resource (Maybe Song))
  -- | Based on a song ID, get information on that song.
  --
  -- Fails if the ID refers to an invalid song.
  GetSong :: SongID -> PlayMusic m (MaybeLoaded Song)
  -- | Based on a song ID, get its artwork, or Nothing if no artwork exists.
  --
  -- Fails if the ID refers to an invalid song.
  GetArtwork :: SongID -> PlayMusic m (Maybe Image)
  -- | Send a command to control the backend
  SendCommand :: Command -> PlayMusic m ()

makeEffect ''PlayMusic
-}
