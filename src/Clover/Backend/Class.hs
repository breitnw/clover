{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

-- What does AllowAmbiguousTypes do?

module Clover.Backend.Class where

import Clover.Backend.Data
import Clover.Backend.Error

import Control.Monad.Except
import Data.Kind

import qualified Codec.Image.STB as STB

class (Monad m, IntoBackendError e, MonadError e m) => MonadBackend e m where
  -- | An identifier (such as a path) that uniquely identifies a song.
  type TrackID m :: Type

  -- | Get an ID uniquely identifying the current song.
  currentSongID :: m (TrackID m)

  -- | Based on a song ID, get information on the current song
  getInfo :: TrackID m -> m (Track (TrackID m))

  -- | Based on a song ID, get its artwork
  getArtwork :: TrackID m -> m STB.Image

  -- | Send a command to control the backend
  sendCommand :: Command -> m ()

-- later, we want ways to enqueue songs, query library, etc
-- might also want to have a setup fn where we prefetch album art for entire library

-- TODO should SongId hold artwork?

-- https://github.com/vimus/libmpd-haskell/blob/master/src/Network/MPD/Core.hs
