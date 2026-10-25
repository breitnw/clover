{-# LANGUAGE PatternSynonyms #-}
{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}

{- |
Module      : Foreign.Lib.MPD.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Foreign.Lib.MPD.Types where

import Foreign.C (CInt (..))

#include <mpd/client.h>

-- MPD.Connection --------------------------------------------------------------

data MPDConnection

newtype MPDError = MPDError CInt
  deriving Eq

pattern MPD_ERROR_SUCCESS                  = MPDError (#const MPD_ERROR_SUCCESS)
pattern MPD_ERROR_OOM                      = MPDError (#const MPD_ERROR_OOM)
pattern MPD_ERROR_ARGUMENT                 = MPDError (#const MPD_ERROR_ARGUMENT)
pattern MPD_ERROR_STATE                    = MPDError (#const MPD_ERROR_STATE)
pattern MPD_ERROR_TIMEOUT                  = MPDError (#const MPD_ERROR_TIMEOUT)
pattern MPD_ERROR_SYSTEM                   = MPDError (#const MPD_ERROR_SYSTEM)
pattern MPD_ERROR_RESOLVER                 = MPDError (#const MPD_ERROR_RESOLVER)
pattern MPD_ERROR_MALFORMED                = MPDError (#const MPD_ERROR_MALFORMED)
pattern MPD_ERROR_CLOSED                   = MPDError (#const MPD_ERROR_CLOSED)
pattern MPD_ERROR_SERVER                   = MPDError (#const MPD_ERROR_SERVER)

-- MPD.Protocol ----------------------------------------------------------------

newtype MPDServerError = MPDServerError CInt
  deriving Eq

pattern MPD_SERVER_ERROR_UNK               = MPDServerError (#const MPD_SERVER_ERROR_UNK)
    
pattern MPD_SERVER_ERROR_NOT_LIST          = MPDServerError (#const MPD_SERVER_ERROR_NOT_LIST)
pattern MPD_SERVER_ERROR_ARG               = MPDServerError (#const MPD_SERVER_ERROR_ARG)
pattern MPD_SERVER_ERROR_PASSWORD          = MPDServerError (#const MPD_SERVER_ERROR_PASSWORD)
pattern MPD_SERVER_ERROR_PERMISSION        = MPDServerError (#const MPD_SERVER_ERROR_PERMISSION)
pattern MPD_SERVER_ERROR_UNKNOWN_CMD       = MPDServerError (#const MPD_SERVER_ERROR_UNKNOWN_CMD)
 
pattern MPD_SERVER_ERROR_NO_EXIST          = MPDServerError (#const MPD_SERVER_ERROR_NO_EXIST)
pattern MPD_SERVER_ERROR_PLAYLIST_MAX      = MPDServerError (#const MPD_SERVER_ERROR_PLAYLIST_MAX)
pattern MPD_SERVER_ERROR_SYSTEM            = MPDServerError (#const MPD_SERVER_ERROR_SYSTEM)
pattern MPD_SERVER_ERROR_PLAYLIST_LOAD     = MPDServerError (#const MPD_SERVER_ERROR_PLAYLIST_LOAD)
pattern MPD_SERVER_ERROR_UPDATE_ALREADY    = MPDServerError (#const MPD_SERVER_ERROR_UPDATE_ALREADY)
pattern MPD_SERVER_ERROR_PLAYER_SYNC       = MPDServerError (#const MPD_SERVER_ERROR_PLAYER_SYNC)
pattern MPD_SERVER_ERROR_EXIST             = MPDServerError (#const MPD_SERVER_ERROR_EXIST)

-- MPD.Song --------------------------------------------------------------------

data MPDSong

-- MPD.Tag ---------------------------------------------------------------------

newtype MPDTag = MPDTag CInt
  deriving Eq

pattern MPD_TAG_UNKNOWN                    = MPDTag (#const MPD_TAG_UNKNOWN)
pattern MPD_TAG_ARTIST                     = MPDTag (#const MPD_TAG_ARTIST)
pattern MPD_TAG_ALBUM                      = MPDTag (#const MPD_TAG_ALBUM)
pattern MPD_TAG_ALBUM_ARTIST               = MPDTag (#const MPD_TAG_ALBUM_ARTIST)
pattern MPD_TAG_TITLE                      = MPDTag (#const MPD_TAG_TITLE)
pattern MPD_TAG_TRACK                      = MPDTag (#const MPD_TAG_TRACK)
pattern MPD_TAG_NAME                       = MPDTag (#const MPD_TAG_NAME)
pattern MPD_TAG_GENRE                      = MPDTag (#const MPD_TAG_GENRE)
pattern MPD_TAG_DATE                       = MPDTag (#const MPD_TAG_DATE)
pattern MPD_TAG_COMPOSER                   = MPDTag (#const MPD_TAG_COMPOSER)
pattern MPD_TAG_PERFORMER                  = MPDTag (#const MPD_TAG_PERFORMER)
pattern MPD_TAG_COMMENT                    = MPDTag (#const MPD_TAG_COMMENT)
pattern MPD_TAG_DISC                       = MPDTag (#const MPD_TAG_DISC)

pattern MPD_TAG_MUSICBRAINZ_ARTISTID       = MPDTag (#const MPD_TAG_MUSICBRAINZ_ARTISTID)
pattern MPD_TAG_MUSICBRAINZ_ALBUMID        = MPDTag (#const MPD_TAG_MUSICBRAINZ_ALBUMID)
pattern MPD_TAG_MUSICBRAINZ_ALBUMARTISTID  = MPDTag (#const MPD_TAG_MUSICBRAINZ_ALBUMARTISTID)
pattern MPD_TAG_MUSICBRAINZ_TRACKID        = MPDTag (#const MPD_TAG_MUSICBRAINZ_TRACKID)
pattern MPD_TAG_MUSICBRAINZ_RELEASETRACKID = MPDTag (#const MPD_TAG_MUSICBRAINZ_RELEASETRACKID)

pattern MPD_TAG_ORIGINAL_DATE              = MPDTag (#const MPD_TAG_ORIGINAL_DATE)

pattern MPD_TAG_ARTIST_SORT                = MPDTag (#const MPD_TAG_ARTIST_SORT)
pattern MPD_TAG_ALBUM_ARTIST_SORT          = MPDTag (#const MPD_TAG_ALBUM_ARTIST_SORT)

pattern MPD_TAG_ALBUM_SORT                 = MPDTag (#const MPD_TAG_ALBUM_SORT)
pattern MPD_TAG_LABEL                      = MPDTag (#const MPD_TAG_LABEL)
pattern MPD_TAG_MUSICBRAINZ_WORKID         = MPDTag (#const MPD_TAG_MUSICBRAINZ_WORKID)

pattern MPD_TAG_GROUPING                   = MPDTag (#const MPD_TAG_GROUPING)
pattern MPD_TAG_WORK                       = MPDTag (#const MPD_TAG_WORK)
pattern MPD_TAG_CONDUCTOR                  = MPDTag (#const MPD_TAG_CONDUCTOR)

pattern MPD_TAG_COMPOSER_SORT              = MPDTag (#const MPD_TAG_COMPOSER_SORT)
pattern MPD_TAG_ENSEMBLE                   = MPDTag (#const MPD_TAG_ENSEMBLE)
pattern MPD_TAG_MOVEMENT                   = MPDTag (#const MPD_TAG_MOVEMENT)
pattern MPD_TAG_MOVEMENTNUMBER             = MPDTag (#const MPD_TAG_MOVEMENTNUMBER)
pattern MPD_TAG_LOCATION                   = MPDTag (#const MPD_TAG_LOCATION)
pattern MPD_TAG_MOOD                       = MPDTag (#const MPD_TAG_MOOD)
pattern MPD_TAG_TITLE_SORT                 = MPDTag (#const MPD_TAG_TITLE_SORT)
pattern MPD_TAG_MUSICBRAINZ_RELEASEGROUPID = MPDTag (#const MPD_TAG_MUSICBRAINZ_RELEASEGROUPID)
