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
import qualified Network.MPD.Core as Core

-- class instance --------------------------------------------------------------

-- | thin wrapper around MPD.MPD
newtype MPDBackend a = MPDBackend {runMPD :: MPD.MPD a}
  deriving (Functor, Applicative, Monad, MonadIO)

{-

instance MonadError MPD.MPDError m => MonadError BackendError m where
  -- NOTE Do not use?? i think
  throwError FileMissing = _
  throwError e = _

  m `catchError` handler =
    MPDBackend $ runMPD m `catchError` (runMPD . handler . toBackendError)
    where
      toBackendError :: MPD.MPDError -> BackendError
      toBackendError MPD.NoMPD = NoBackend
      toBackendError (MPD.ConnectionError e) = ConnectionError e
      -- toBackendError
      toBackendError e = Unexpected $ show e

-- TODO use mapError?

-}

instance MonadBackend MPDBackend MPD.MPDError where
  type TrackID MPDBackend = MPD.Path
  currentSongID = mbCurrentSong
  getInfo = mbGetInfo
  getArtwork = _
  sendCommand = _

mpdbCurrentSong :: MPDBackend (Maybe MPD.Path)
mpdbCurrentSong = MPDBackend $ fmap MPD.sgFilePath <$> MPD.currentSong

-- TODO don't use head, throw error if missing?
mpdbGetInfo :: MPD.Path -> MPDBackend (Track MPD.Path)
mpdbGetInfo path = MPDBackend $ toTrack . head <$> MPD.find (MPD.qFile path)

-- mbGetArtwork

-- converters ------------------------------------------------------------------

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

-- artwork fetching ------------------------------------------------------------

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
      (MPD.AlbumArtChunk fileSize' _ bytes) <- MPD.albumArt uri (fromIntegral offset)
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
  bytes' <- getArtworkBytes uri
  case bytes' of
    Left err -> return $ Left err
    Right bytes -> liftIO $ STB.decodeImage bytes

-- based on https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L337
