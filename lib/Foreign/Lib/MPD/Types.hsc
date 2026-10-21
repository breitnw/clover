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

pattern MPD_TAG_UNKNOWN                    = MPDServerError (#const MPD_TAG_UNKNOWN)
pattern MPD_TAG_ARTIST                     = MPDServerError (#const MPD_TAG_ARTIST)
pattern MPD_TAG_ALBUM                      = MPDServerError (#const MPD_TAG_ALBUM)
pattern MPD_TAG_ALBUM_ARTIST               = MPDServerError (#const MPD_TAG_ALBUM_ARTIST)
pattern MPD_TAG_TITLE                      = MPDServerError (#const MPD_TAG_TITLE)
pattern MPD_TAG_TRACK                      = MPDServerError (#const MPD_TAG_TRACK)
pattern MPD_TAG_NAME                       = MPDServerError (#const MPD_TAG_NAME)
pattern MPD_TAG_GENRE                      = MPDServerError (#const MPD_TAG_GENRE)
pattern MPD_TAG_DATE                       = MPDServerError (#const MPD_TAG_DATE)
pattern MPD_TAG_COMPOSER                   = MPDServerError (#const MPD_TAG_COMPOSER)
pattern MPD_TAG_PERFORMER                  = MPDServerError (#const MPD_TAG_PERFORMER)
pattern MPD_TAG_COMMENT                    = MPDServerError (#const MPD_TAG_COMMENT)
pattern MPD_TAG_DISC                       = MPDServerError (#const MPD_TAG_DISC)

pattern MPD_TAG_MUSICBRAINZ_ARTISTID       = MPDServerError (#const MPD_TAG_MUSICBRAINZ_ARTISTID)
pattern MPD_TAG_MUSICBRAINZ_ALBUMID        = MPDServerError (#const MPD_TAG_MUSICBRAINZ_ALBUMID)
pattern MPD_TAG_MUSICBRAINZ_ALBUMARTISTID  = MPDServerError (#const MPD_TAG_MUSICBRAINZ_ALBUMARTISTID)
pattern MPD_TAG_MUSICBRAINZ_TRACKID        = MPDServerError (#const MPD_TAG_MUSICBRAINZ_TRACKID)
pattern MPD_TAG_MUSICBRAINZ_RELEASETRACKID = MPDServerError (#const MPD_TAG_MUSICBRAINZ_RELEASETRACKID)

pattern MPD_TAG_ORIGINAL_DATE              = MPDServerError (#const MPD_TAG_ORIGINAL_DATE)

pattern MPD_TAG_ARTIST_SORT                = MPDServerError (#const MPD_TAG_ARTIST_SORT)
pattern MPD_TAG_ALBUM_ARTIST_SORT          = MPDServerError (#const MPD_TAG_ALBUM_ARTIST_SORT)

pattern MPD_TAG_ALBUM_SORT                 = MPDServerError (#const MPD_TAG_ALBUM_SORT)
pattern MPD_TAG_LABEL                      = MPDServerError (#const MPD_TAG_LABEL)
pattern MPD_TAG_MUSICBRAINZ_WORKID         = MPDServerError (#const MPD_TAG_MUSICBRAINZ_WORKID)

pattern MPD_TAG_GROUPING                   = MPDServerError (#const MPD_TAG_GROUPING)
pattern MPD_TAG_WORK                       = MPDServerError (#const MPD_TAG_WORK)
pattern MPD_TAG_CONDUCTOR                  = MPDServerError (#const MPD_TAG_CONDUCTOR)

pattern MPD_TAG_COMPOSER_SORT              = MPDServerError (#const MPD_TAG_COMPOSER_SORT)
pattern MPD_TAG_ENSEMBLE                   = MPDServerError (#const MPD_TAG_ENSEMBLE)
pattern MPD_TAG_MOVEMENT                   = MPDServerError (#const MPD_TAG_MOVEMENT)
pattern MPD_TAG_MOVEMENTNUMBER             = MPDServerError (#const MPD_TAG_MOVEMENTNUMBER)
pattern MPD_TAG_LOCATION                   = MPDServerError (#const MPD_TAG_LOCATION)
pattern MPD_TAG_MOOD                       = MPDServerError (#const MPD_TAG_MOOD)
pattern MPD_TAG_TITLE_SORT                 = MPDServerError (#const MPD_TAG_TITLE_SORT)
pattern MPD_TAG_MUSICBRAINZ_RELEASEGROUPID = MPDServerError (#const MPD_TAG_MUSICBRAINZ_RELEASEGROUPID)
