{-# LANGUAGE CApiFFI #-}
{-# LANGUAGE ForeignFunctionInterface #-}

{- |
Module      : Foreign.Lib.MPD.FFI
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Foreign.Lib.MPD.FFI where

import Foreign (Ptr)
import Foreign.C (CBool (..), CInt (..), CUInt (..))
import Foreign.C.ConstPtr (ConstPtr (..))

import Foreign.Lib.MPD.Types
import Foreign.Util

-- TODO make sure safe/unsafe is used properly

-- MPD.Connection --------------------------------------------------------------

foreign import capi unsafe "mpd/connection.h mpd_connection_new"
  mpdConnectionNew :: ConstCString -> CUInt -> CUInt -> IO (Ptr MPDConnection)
foreign import capi unsafe "mpd/connection.h mpd_connection_free"
  mpdConnectionFree :: Ptr MPDConnection -> IO ()
foreign import capi unsafe "mpd/connection.h mpd_connection_get_error"
  mpdConnectionGetError :: Ptr MPDConnection -> IO MPDError
foreign import capi unsafe "mpd/connection.h mpd_connection_get_error_message"
  mpdConnectionGetErrorMessage :: Ptr MPDConnection -> IO ConstCString
foreign import capi unsafe "mpd/connection.h mpd_connection_get_server_error"
  mpdConnectionGetServerError :: Ptr MPDConnection -> IO MPDServerError

-- MPD.Player ------------------------------------------------------------------

foreign import capi unsafe "mpd/player.h mpd_run_current_song"
  mpdRunCurrentSong :: Ptr MPDConnection -> IO (Ptr MPDSong)
foreign import capi unsafe "mpd/player.h mpd_run_play"
  mpdRunPlay :: Ptr MPDConnection -> IO CBool
foreign import capi unsafe "mpd/player.h mpd_run_stop"
  mpdRunStop :: Ptr MPDConnection -> IO CBool
foreign import capi unsafe "mpd/player.h mpd_run_pause"
  mpdRunPause :: Ptr MPDConnection -> CBool -> IO CBool

-- MPD.Song --------------------------------------------------------------------

foreign import capi unsafe "mpd/song.h mpd_song_free"
  mpdSongFree :: Ptr MPDSong -> IO ()
foreign import capi unsafe "mpd/song.h mpd_song_get_uri"
  mpdSongGetURI :: Ptr MPDSong -> IO ConstCString
foreign import capi unsafe "mpd/song.h mpd_song_get_tag"
  mpdSongGetTag :: Ptr MPDSong -> MPDTag -> CUInt -> IO ConstCString
foreign import capi unsafe "mpd/song.h mpd_song_get_duration"
  mpdSongGetDuration :: Ptr MPDSong -> IO CUInt
foreign import capi unsafe "mpd/song.h mpd_song_get_duration_ms"
  mpdSongGetDurationMs :: Ptr MPDSong -> IO CUInt
