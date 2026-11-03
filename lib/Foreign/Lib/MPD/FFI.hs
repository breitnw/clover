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
import Foreign.C (CBool (..), CInt (..), CSize (..), CUInt (..))
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
foreign import capi unsafe "mpd/connection.h mpd_connection_clear_error"
  mpdConnectionClearError :: Ptr MPDConnection -> IO CBool

-- MPD.Player ------------------------------------------------------------------

foreign import capi unsafe "mpd/player.h mpd_run_current_song"
  mpdRunCurrentSong :: Ptr MPDConnection -> IO (Ptr MPDSong)
foreign import capi unsafe "mpd/player.h mpd_run_play"
  mpdRunPlay :: Ptr MPDConnection -> IO CBool
foreign import capi unsafe "mpd/player.h mpd_run_stop"
  mpdRunStop :: Ptr MPDConnection -> IO CBool
foreign import capi unsafe "mpd/player.h mpd_run_pause"
  mpdRunPause :: Ptr MPDConnection -> CBool -> IO CBool
foreign import capi unsafe "mpd/player.h mpd_run_next"
  mpdRunNext :: Ptr MPDConnection -> IO CBool
foreign import capi unsafe "mpd/player.h mpd_run_previous"
  mpdRunPrevious :: Ptr MPDConnection -> IO CBool

-- TODO there seem to be other error handling methods too, figure out which to use
-- foreign import capi unsafe "mpd/player.h mpd_clear_error"
--   mpdClearError :: Ptr MPDConnection -> IO CBool

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

-- MPD.ReadPicture -------------------------------------------------------------

-- foreign import capi unsafe "mpd/readpicture.h mpd_run_readpicture"
--   mpdReadPicture
--     :: Ptr MPDConnection
--     -- ^ A valid and connected MPDConnection
--     -> ConstCString
--     -- ^ The URI of the song
--     -> CUInt
--     -- ^ Offset to read from
--     -> Ptr ()
--     -- ^ An already allocated buffer, the size must be the same or greater than
--     -- the binary chunk size (default 8192, can be set with binarylimit command)
--     -> CSize
--     -- ^ Size of the allocated buffer
--     -> IO CInt
--     -- ^ Read size on success, -1 on failure

-- | Read album art from a tag.
foreign import capi unsafe "mpd/readpicture.h mpd_send_readpicture"
  mpdSendReadPicture
    :: Ptr MPDConnection
    -- ^ The current MPD connection
    -> ConstCString
    -- ^ The URI of the song
    -> CUInt
    -- ^ Offset
    -> IO CBool
    -- ^ False on failure

-- TODO make sure that errors are cleared before re-running?

-- | Receive a readpicture response.
--
-- -1 if the album art cannot be read for any reason. If there is no tag present
-- present, the current error will be MPD_ERROR_SUCCESS
foreign import capi unsafe "mpd/readpicture.h mpd_recv_readpicture"
  mpdRecvReadPicture
    :: Ptr MPDConnection
    -- ^ The current MPD connection
    -> Ptr ()
    -- ^ An already allocated buffer, the size must be the same or greater than
    -- the binary chunk size (default 8192, can be set with binarylimit command)
    -> CSize
    -- ^ Size of the allocated buffer
    -> IO CInt
    -- ^ Read size on success, -1 on failure

-- MPD.AlbumArt ----------------------------------------------------------------

-- foreign import capi unsafe "mpd/albumart.h mpd_run_albumart"
--   mpdAlbumArt
--     :: Ptr MPDConnection
--     -- ^ A valid and connected MPDConnection
--     -> ConstCString
--     -- ^ The URI of the song
--     -> CUInt
--     -- ^ Offset to read from
--     -> Ptr ()
--     -- ^ An already allocated buffer, the size must be the same or greater than
--     -- the binary chunk size (default 8192, can be set with binarylimit command)
--     -> CSize
--     -- ^ Size of the allocated buffer
--     -> IO CInt
--     -- ^ Read size on success, -1 on failure

-- | Read album art from a file.
foreign import capi unsafe "mpd/albumart.h mpd_send_albumart"
  mpdSendAlbumArt
    :: Ptr MPDConnection
    -- ^ The current MPD connection
    -> ConstCString
    -- ^ The URI of the song
    -> CUInt
    -- ^ Offset
    -> IO CBool
    -- ^ False on failure

-- | Receive an albumart response.
--
-- -1 if the album art cannot be read for any reason. If there is no such tag,
-- fails with `MPD_SERVER_ERROR_NO_EXIST`.
foreign import capi unsafe "mpd/albumart.h mpd_recv_albumart"
  mpdRecvAlbumArt
    :: Ptr MPDConnection
    -- ^ The current MPD connection
    -> Ptr ()
    -- ^ An already allocated buffer, the size must be the same or greater than
    -- the binary chunk size (default 8192, can be set with binarylimit command)
    -> CSize
    -- ^ Size of the allocated buffer
    -> IO CInt
    -- ^ Read size on success, -1 on failure

-- MPD.Recv --------------------------------------------------------------------

foreign import capi unsafe "mpd/recv.h mpd_recv_pair_named"
  mpdRecvPairNamed :: Ptr MPDConnection -> ConstCString -> IO (Ptr MPDPair)
foreign import capi unsafe "mpd/recv.h mpd_return_pair"
  mpdReturnPair :: Ptr MPDConnection -> Ptr MPDPair -> IO ()

-- MPD.Response ----------------------------------------------------------------

foreign import capi unsafe "mpd/response.h mpd_response_finish"
  mpdResponseFinish :: Ptr MPDConnection -> IO CBool
