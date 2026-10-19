{- |
Module      : Foreign.Lib.MPD.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Foreign.Lib.MPD.Types where

import Foreign.C (CInt (..))

-- TODO use `enum` for SDL too?

#include <mpd/client.h>

-- MPD.Connection --------------------------------------------------------------

data MPDConnection

type MPDError = CInt
mpdErrorSuccess = #{const MPD_ERROR_SUCCESS} :: MPDError
-- #{enum MPDError MPDError
--     MPD_ERROR_SUCCESS
--     MPD_ERROR_OOM
--     MPD_ERROR_ARGUMENT
--     MPD_ERROR_STATE
--     MPD_ERROR_TIMEOUT
--     MPD_ERROR_SYSTEM
--     MPD_ERROR_RESOLVER
--     MPD_ERROR_MALFORMED
--     MPD_ERROR_CLOSED
--     MPD_ERROR_SERVER}

-- MPD.Protocol ----------------------------------------------------------------

newtype MPDServerError = MPDServerError CInt
#{enum MPDServerError MPDServerError
    MPD_SERVER_ERROR_UNK
    
    MPD_SERVER_ERROR_NOT_LIST
    MPD_SERVER_ERROR_ARG
    MPD_SERVER_ERROR_PASSWORD
    MPD_SERVER_ERROR_PERMISSION
    MPD_SERVER_ERROR_UNKNOWN_CMD

    MPD_SERVER_ERROR_NO_EXIST
    MPD_SERVER_ERROR_PLAYLIST_MAX
    MPD_SERVER_ERROR_SYSTEM
    MPD_SERVER_ERROR_PLAYLIST_LOAD
    MPD_SERVER_ERROR_UPDATE_ALREADY
    MPD_SERVER_ERROR_PLAYER_SYNC
    MPD_SERVER_ERROR_EXIST}

-- MPD.Song --------------------------------------------------------------------

data MPDSong

-- MPD.Tag ---------------------------------------------------------------------

newtype MPDTag = MPDTag CInt
#{enum MPDTag MPDTag
    MPD_TAG_UNKNOWN
    MPD_TAG_ARTIST
    MPD_TAG_ALBUM
    MPD_TAG_ALBUM_ARTIST
    MPD_TAG_TITLE
    MPD_TAG_TRACK
    MPD_TAG_NAME
    MPD_TAG_GENRE
    MPD_TAG_DATE
    MPD_TAG_COMPOSER
    MPD_TAG_PERFORMER
    MPD_TAG_COMMENT
    MPD_TAG_DISC

    MPD_TAG_MUSICBRAINZ_ARTISTID
    MPD_TAG_MUSICBRAINZ_ALBUMID
    MPD_TAG_MUSICBRAINZ_ALBUMARTISTID
    MPD_TAG_MUSICBRAINZ_TRACKID
    MPD_TAG_MUSICBRAINZ_RELEASETRACKID

    MPD_TAG_ORIGINAL_DATE

    MPD_TAG_ARTIST_SORT
    MPD_TAG_ALBUM_ARTIST_SORT

    MPD_TAG_ALBUM_SORT
    MPD_TAG_LABEL
    MPD_TAG_MUSICBRAINZ_WORKID

    MPD_TAG_GROUPING
    MPD_TAG_WORK
    MPD_TAG_CONDUCTOR

    MPD_TAG_COMPOSER_SORT
    MPD_TAG_ENSEMBLE
    MPD_TAG_MOVEMENT
    MPD_TAG_MOVEMENTNUMBER
    MPD_TAG_LOCATION
    MPD_TAG_MOOD
    MPD_TAG_TITLE_SORT
    MPD_TAG_MUSICBRAINZ_RELEASEGROUPID}
