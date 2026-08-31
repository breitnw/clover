{- |
Module      : Effectful.Backend.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Backend.Effect (
  Backend (..),
  currentSong,
  getSong,
  getArtwork,
  sendCommand,
) where

import Codec.Image.STB qualified as STB
import Effectful
import Effectful.Dispatch.Dynamic

import Effectful.Backend.Types

-- | Interface implemented by the music player backend.
--
-- Implementors of this interface may be blocking. Scheduling should be handled
-- by the user of the effect.
data Backend :: Effect where
  CurrentSong :: Backend m (Maybe Song)
  GetSong :: SongID -> Backend m Song
  GetArtwork :: SongID -> Backend m (Maybe STB.Image)
  SendCommand :: Command -> Backend m ()

type instance DispatchOf Backend = Dynamic

-- | Get the currently playing song.
--
-- If there is no song currently playing, returns Nothing.
currentSong :: Backend :> es => Eff es (Maybe Song)
currentSong = send CurrentSong

-- | Based on a song ID, get information on that song.
--
-- Fails (via the MonadError instance) if the ID refers to an invalid song.
getSong :: Backend :> es => SongID -> Eff es Song
getSong = send . GetSong

-- | Based on a song ID, get its artwork.
--
-- Fails (via the MonadError instance) if the ID refers to an invalid song.
getArtwork :: Backend :> es => SongID -> Eff es (Maybe STB.Image)
getArtwork = send . GetArtwork

-- | Send a command to control the backend
sendCommand :: Backend :> es => Command -> Eff es ()
sendCommand = send . SendCommand

{- NOTES

later, we want ways to enqueue songs, query library, etc
might also want to have a setup fn where we prefetch album art for entire library

TODO should SongId hold artwork?

https://github.com/vimus/libmpd-haskell/blob/master/src/Network/MPD/Core.hs

-}
