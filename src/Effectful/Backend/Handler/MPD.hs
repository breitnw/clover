{- |
Module      : Effectful.Backend.Handler.MPD
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

MPD handler for the 'Effectful.Backend.Backend' effect.
-}
module Effectful.Backend.Handler.MPD where

import Control.Applicative ((<|>))
import Data.Map ((!?))
import Data.String (fromString)

import Codec.Image.STB qualified as STB
import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Error.Dynamic
import Effectful.Log qualified as Log
import Effectful.Network.MPD qualified as MPD

import Effectful.Backend.Data
import Effectful.Backend.Effect
import Util

-- EFFECT HANDLER --------------------------------------------------------------

-- NOTE takes away the ability to catch errors... so all error handling can be
-- dealt with outside the handler, I think?

withMPDBackend
  :: (IOE :> es, Log :> es) -- IOE needed for image loading as well as MPD
  => MPD.Host
  -> MPD.Port
  -> MPD.Password
  -> Eff (Backend : es) a
  -> Eff es (Either MPD.MPDError a)
withMPDBackend host port pw = reinterpret_ runMPD $ \case
  CurrentSong -> fmap asCloverSong <$> MPD.currentSong
  GetSong songId -> getSong' songId
  GetArtwork songId -> getArtwork' songId
  SendCommand cmd -> sendCommand' cmd
  where
    runMPD = MPD.withEMPDEx host port pw

getSong'
  :: (MPD.EMPD :> es, Error MPD.MPDError :> es)
  => SongID
  -> Eff es Song
getSong' (SongID sid) = do
  -- NOTE this is slow (intermediate string conversion), is there a better way?
  let path = fromString $ unpack sid :: MPD.Path
  results <- MPD.find (MPD.qFile path)
  case results of
    [a] -> return $ asCloverSong a
    _ ->
      throwError $
        MPD.Custom $
          "Expected exactly one match for track ID "
            ++ show sid
            ++ ", got: "
            ++ show (length results)

getArtwork'
  :: (MPD.EMPD :> es, Error MPD.MPDError :> es, Log :> es) -- , IOE :> es)
  => SongID
  -> Eff es (Maybe STB.Image)
getArtwork' (SongID sid) = do
  let path = fromString $ unpack sid :: MPD.Path
  -- FIXME nope i don't think this works
  im <-
    getArtworkFromCache `orElseDo` getArtworkFromFile `orElseDo` getArtworkFromTag
  -- let maybeAlbumArt path' offset =
  --       MPD.readPicture path' offset
  --         `catchError` \_ e -> case e of
  --           MPD.ACK MPD.FileNotFound _ -> return Nothing
  --           _ -> throwError e
  -- bytes
  -- logTrace "Attempting to find album art (file)" path
  -- fileContents <- getArtworkBytes path maybeAlbumArt
  -- case fileContents of
  --   Nothing ->
  -- 3. attempt to get album art from the binary tag (readPicture)
  -- tagContents <- getArtworkBytes path MPD.readPicture
  -- TODO

  -- HACK
  return Nothing
  where
    path = fromString $ unpack sid

    -- 1. check the cache to see if we already have the album art downloaded
    getArtworkFromCache :: Eff es (Maybe STB.Image)
    getArtworkFromCache = return Nothing -- TODO

    -- 2. attempt to get album art file (albumArt)
    getArtworkFromFile :: Eff es (Maybe STB.Image)
    getArtworkFromFile =
      getArtworkBytes
        (\offset -> (Just <$> MPD.albumArt path offset) `catchError` handler)
        >>= _
      where
        handler _ (MPD.ACK MPD.FileNotFound _) = return Nothing
        handler _ e = throwError e

    -- 3. attempt to get album art from the binary tag (readPicture)
    getArtworkFromTag :: Eff es (Maybe STB.Image)
    getArtworkFromTag = getArtworkBytes (MPD.readPicture path)

sendCommand'
  :: (MPD.EMPD :> es, Error MPD.MPDError :> es)
  => Command
  -> Eff es ()
sendCommand' PlayPause = MPD.toggle
sendCommand' Next = MPD.next
sendCommand' Previous = MPD.previous

-- CONVERTERS ------------------------------------------------------------------

-- | Convert an MPD song to a Clover song.
asCloverSong :: MPD.Song -> Song
asCloverSong s =
  Song
    { title = tagValue MPD.Title
    , artist = tagValue MPD.Artist
    , album = tagValue MPD.Album
    , songID = SongID $ MPD.toText $ MPD.sgFilePath s
    }
  where
    tags = MPD.sgTags s
    tagValue :: MPD.Metadata -> Maybe Text
    tagValue tag = case tags !? tag of
      -- Use the first tag if one exists
      Just (val : _) -> Just $ MPD.toText val
      -- If there are 0 values or the tag doesn't exist, return Nothing
      _ -> Nothing

-- ARTWORK HELPERS -------------------------------------------------------------

-- | Get the album artwork of the song at the given uri as raw bytes.
getArtworkBytes
  :: forall es
   . (MPD.EMPD :> es, Error MPD.MPDError :> es, Log :> es)
  => (Integer -> Eff es (Maybe MPD.AlbumArtChunk))
  -- ^ Command to get a chunk of the album art (either readPicture or albumArt)
  -> Eff es (Maybe BS.ByteString)
  -- ^ Full album art as raw bytes
getArtworkBytes path getAlbumArtChunk = go BS.empty path
  where
    go :: BS.ByteString -> MPD.Path -> Eff es (Maybe BS.ByteString)
    go acc uri = do
      -- query mpd for the chunk
      let offset = BS.length acc
      chunk <- getAlbumArtChunk uri (fromIntegral offset)
      case chunk of
        Nothing -> return Nothing
        Just (MPD.AlbumArtChunk fileSize' _ bytes) -> do
          let fileSize = fromInteger fileSize'
          let chunkSize = BS.length bytes
          -- report progress
          let progress = div (100 * (offset + chunkSize)) fileSize
          logTrace "progress" progress -- TODO use SDLlog instead of effect to enable output on windows builds
          -- append to the string and repeat
          let acc' = acc <> bytes
          if offset + chunkSize >= fileSize
            then return $ Just acc'
            else go acc' uri
