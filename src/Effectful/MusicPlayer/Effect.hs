{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.MusicPlayer.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.MusicPlayer.Effect (
  PlayMusic (..),
  currentSong,
  getSong,
  getArtwork,
  sendCommand,
) where

import Codec.Image.STB qualified as STB
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
  -- | Based on a song ID, get information on that song.
  --
  -- Fails if the ID refers to an invalid song.
  GetSong :: SongID -> PlayMusic m Song
  -- | Based on a song ID, get its artwork.
  --
  -- Fails if the ID refers to an invalid song.
  GetArtwork :: SongID -> PlayMusic m (Maybe STB.Image)
  -- | Send a command to control the backend
  SendCommand :: Command -> PlayMusic m ()

makeEffect ''PlayMusic

{- NOTES

later, we want ways to enqueue songs, query library, etc
might also want to have a setup fn where we prefetch album art for entire library

TODO should SongId hold artwork?

https://github.com/vimus/libmpd-haskell/blob/master/src/Network/MPD/Core.hs

-}
