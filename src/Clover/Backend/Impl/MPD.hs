{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module Clover.Backend.Impl.MPD where

import Clover.Backend.Class
import Clover.Backend.Data
import Clover.Backend.Error

import Control.Monad.Except
import Control.Monad.IO.Class

import qualified Codec.Image.STB as STB
import qualified Data.ByteString as BS
import qualified Network.MPD as MPD

-- class instance --------------------------------------------------------------

newtype MPDError = MPDError {getError :: MPD.MPDError}

-- | thin wrapper around MPD with expected error type
newtype MPDBackend a = MPDBackend {runMPD :: ExceptT BackendError MPD.MPD a}
  deriving (Functor, Applicative, Monad, MonadIO, MonadError MPDError)

instance IntoBackendError MPD.MPDError where
  intoBackendError err = Unknown $ show err

instance MonadBackend MPD.MPDError MPDBackend where
  type TrackID MPDBackend = MPD.Path
  currentSongID = _
  getInfo = _
  getArtwork = _
  sendCommand = _

-- | Convert a MPD song into a Clover track
toTrack :: MPD.Song -> Track MPD.Path
toTrack s =
  Song
    { title = getTagStr MPD.Title "Unknown Title"
    , artist = getTagStr MPD.Artist "Unknown Artist"
    , album = getTagStr MPD.Album "Unknown Artist"
    , trackID = MPD.sgFilePath s
    }
  where
    tags = MPD.sgTags s
    getTagStr :: MPD.Metadata -> String -> String
    getTagStr tag defaultStr =
      maybe
        defaultStr
        (MPD.toString . head)
        (tags !? tag)

-- song fetchers ---------------------------------------------------------------

getInfo :: MPD.Path -> MPD.MPD (Track MPD.Path)
getInfo = fmap toSongWithPlaceholders <$> MPD.currentSong

-- TODO make this an ExceptT to collect user errors, display later?
-- depends on whether server should die if there is an unexpected error

-- artwork fetchers ------------------------------------------------------------

-- | Get the album artwork of the song at the given uri as raw bytes
getArtworkBytes :: MPD.Path -> MPD.MPD (Either String BS.ByteString)
getArtworkBytes path = (Right <$> go BS.empty path) `catchError` handler
  where
    handler :: MPD.MPDError -> MPD.MPD (Either String BS.ByteString)
    handler (MPD.ACK MPD.FileNotFound _) = do
      return $ Left "Album artwork not found"
    handler e = throwError e

    go :: BS.ByteString -> MPD.Path -> MPD.MPD BS.ByteString
    go acc uri = do
      -- query mpd for the chunk
      let offset = BS.length acc
      (MPD.AlbumArtChunk fileSize' bytes) <- MPD.albumArt uri (fromIntegral offset)
      let fileSize = fromInteger fileSize'
      let chunkSize = BS.length bytes
      -- report progress
      liftIO $
        putStrLn $
          "progress: "
            ++ show (div (100 * (offset + chunkSize)) fileSize)
            ++ "%"
      -- append to the string and repeat
      let acc' = acc <> bytes
      if offset + chunkSize >= fileSize
        then return acc'
        else go acc' uri

-- TODO would be better if this were an ExceptT, wouldn't need the cases
-- any way to do this without ExceptT?

-- | Get the album artwork of the song at the given uri as a bitmap
getArtworkBitmap :: MPD.Path -> MPD.MPD (Either String STB.Image)
getArtworkBitmap uri = do
  bytes' <- getArtwork uri
  case bytes' of
    Left err -> return $ Left err
    Right bytes -> liftIO $ STB.decodeImage bytes

-- based on https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L337
