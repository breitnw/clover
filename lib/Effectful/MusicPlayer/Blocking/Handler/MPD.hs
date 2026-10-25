{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effectful.MusicPlayer.Blocking.Handler.MPD
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

MPD handler for the 'Effectful.MusicPlayer.PlayMusic' effect.
-}
module Effectful.MusicPlayer.Blocking.Handler.MPD (
  runMPDMusicPlayerBlocking,
  MPDConfig (..),
) where

import Control.Monad (unless, when)
import Foreign (fromBool, toBool)
import Foreign.C (CInt, CSize, CUInt)
import Foreign.Ptr

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Error.Dynamic
import Effectful.Exception
import Effectful.Reader.Static
import Effectful.State.Static.Local

import Effectful.Logger
import Effectful.MusicPlayer.Blocking
import Foreign.Lib.MPD qualified as F
import Foreign.Util

-- SUPPORTING TYPES ------------------------------------------------------------

type ArtworkFetcher = CUInt -> Ptr () -> CSize -> CInt

-- | Current internal state of artwork fetching process.
data ArtworkState = ArtworkState
  { albumArtID :: T.Text
  , albumArtFetcher :: ArtworkFetcher
  , albumArtOffset :: CUInt
  , albumArtBuffer :: Ptr ()
  , albumArtBufferSize :: Ptr ()
  }

-- TODO since MPD is reused in Continuous, might be a better idea to
data MPDConfig = MPDConfig
  { mcHost :: T.Text
  , mcPort :: Maybe Int -- Nothing for default port (using MPD_PORT)
  , mcPassword :: Maybe T.Text -- Nothing for no password
  , mcTimeout :: Maybe Int -- Nothing for default timeout (using MPD_TIMEOUT)
  }

-- LOW-LEVEL ERROR HANDLING ----------------------------------------------------

newtype MPDException = MPDException T.Text
  deriving (Show)

instance Exception MPDException

-- libmpdclient likes to return NULL when out of memory, so handle this situation
handleOOM :: IOE :> es => Ptr a -> Eff es ()
handleOOM ptr = when (ptr == nullPtr) $ throwIO (MPDException "Out of memory")

-- handle errors from mpdConnectionGetError
handleMPDErrors :: IOE :> es => Ptr F.MPDConnection -> Eff es ()
handleMPDErrors conn = do
  err <- liftIO $ F.mpdConnectionGetError conn
  unless (err == F.MPD_ERROR_SUCCESS) $ do
    msg <- liftIO $ F.mpdConnectionGetErrorMessage conn
    -- TODO clear the error in case user recovers
    msgText <- liftIO $ peekConstCString msg
    throwIO $ MPDException msgText

-- EFFECT HANDLER --------------------------------------------------------------

type MPDEffects es = (Reader (Ptr F.MPDConnection) : State ArtworkState : es)

runMPDMusicPlayerBlocking
  :: forall es a
   . (IOE :> es, Log :> es)
  => MPDConfig
  -> Eff (PlayMusic : es) a
  -> Eff es a
runMPDMusicPlayerBlocking (MPDConfig host port password timeout) =
  -- TODO set password
  reinterpret_ runMPD $ \case
    -- CurrentSong -> fmap asCloverSong <$> MPD.currentSong
    -- GetSong songId -> getSong' songId
    -- GetArtwork songId -> getArtwork' songId
    CurrentSong -> currentSong'
    LoadArtwork songID -> loadArtwork' songID
    SendCommand cmd -> sendCommand' cmd
  where
    runMPD op = bracket openMPD closeMPD $ \conn -> do
      handleOOM conn
      handleMPDErrors conn
      runReader conn $
        evalState @(Maybe ArtworkState) Nothing op

    -- Open a MPD connection. Only checks for out of memory errors.
    openMPD = do
      logInfo "Opening MPD connection"
      liftIO $ withConstCString host $ \hostCStr ->
        F.mpdConnectionNew
          hostCStr
          (maybe 0 fromIntegral port)
          (maybe 0 fromIntegral timeout)

    -- Close an MPD connection.
    closeMPD :: Ptr F.MPDConnection -> Eff es ()
    closeMPD conn = do
      logInfo "Closing MPD connection"
      liftIO $ F.mpdConnectionFree conn

currentSong'
  :: (IOE :> es, Reader (Ptr F.MPDConnection) :> es)
  => Eff es (Maybe Song)
currentSong' = do
  conn <- ask
  bracket (getCurrentSong conn) destroySong $ \song -> do
    handleMPDErrors conn
    if song == nullPtr
      then return Nothing
      else do
        title <- maybeGetTagText =<< liftIO (F.mpdSongGetTag song F.MPD_TAG_TITLE 0)
        artist <- maybeGetTagText =<< liftIO (F.mpdSongGetTag song F.MPD_TAG_ARTIST 0)
        album <- maybeGetTagText =<< liftIO (F.mpdSongGetTag song F.MPD_TAG_ALBUM 0)
        duration <-
          -- duration of 0 means unknown
          (\i -> if i == 0 then Nothing else Just i)
            . fromIntegral
            <$> liftIO (F.mpdSongGetDurationMs song)
        songID <- SongID <$> (getTagText =<< liftIO (F.mpdSongGetURI song))
        return $ Just $ Song title artist album duration songID
  where
    -- Get current song without checking for errors.
    getCurrentSong conn = liftIO (F.mpdRunCurrentSong conn)

    -- Free memory allocated for a song.
    destroySong = liftIO . F.mpdSongFree

    -- Convert a tag value (constCString) to text.
    getTagText = liftIO . peekConstCString

    -- Convert a tag value (constCString) to text, or Nothing if null
    maybeGetTagText rawTag =
      if rawTag == constNullPtr
        then return Nothing
        else Just <$> getTagText rawTag

loadArtwork'
  :: ( IOE :> es
     , State (Maybe ArtworkState) :> es
     , Reader (Ptr F.MPDConnection) :> es
     )
  => SongID
  -> Eff es (Status (Maybe BS.ByteString))
loadArtwork' id = do
  -- TODO
  return Waiting

sendCommand'
  :: ( IOE :> es
     , Reader (Ptr F.MPDConnection) :> es
     )
  => Command
  -> Eff es ()
sendCommand' cmd = do
  conn <- ask
  res <- liftIO $ case cmd of
    Play -> F.mpdRunPlay conn
    Pause -> F.mpdRunPause conn (fromBool True)
    Resume -> F.mpdRunPause conn (fromBool False)
    Next -> F.mpdRunNext conn
    Previous -> F.mpdRunNext conn
  unless (toBool res) $ handleMPDErrors conn

{-
getSong'
  :: (MPD.EMPD :> es, Error MPD.MPDError :> es)
  => SongID
  -> Eff es Song
getSong' (SongID sid) = do
  -- NOTE this is slow (intermediate string conversion), is there a better way?
  let path = fromString $ T.unpack sid :: MPD.Path
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
  :: forall es
   . ( MPD.EMPD :> es
     , Error MPD.MPDError :> es
     , Log :> es
     , LoadImages :> es
     )
  => SongID
  -> Eff es (Maybe Image)
getArtwork' (SongID sid) =
  getArtworkFromCache
    `orElseDo` getArtworkFromFile
    `orElseDo` getArtworkFromTag
  where
    path = fromString $ T.unpack sid

    -- 1. check the cache to see if we already have the album art downloaded
    getArtworkFromCache :: Eff es (Maybe Image)
    getArtworkFromCache = do
      logInfo "Trying to fetch artwork from cache"
      return Nothing -- TODO

    -- 2. attempt to get album art file (albumArt)
    getArtworkFromFile :: Eff es (Maybe Image)
    getArtworkFromFile = do
      logInfo "Trying to fetch artwork from file"
      bytes <-
        getArtworkBytes
          (\offset -> (Just <$> MPD.albumArt path offset) `catchError` handler)
      case bytes of
        Nothing -> return Nothing
        Just b -> rightToMaybe <$> loadImageBytes ("file@" <> sid) b
      where
        handler _ (MPD.ACK MPD.FileNotFound _) = return Nothing
        handler _ e = throwError e

    -- 3. attempt to get album art from the binary tag (readPicture)
    getArtworkFromTag :: Eff es (Maybe Image)
    getArtworkFromTag = do
      logInfo "Trying to fetch artwork from tag"
      bytes <- getArtworkBytes (MPD.readPicture path)
      case bytes of
        Nothing -> return Nothing
        Just b -> rightToMaybe <$> loadImageBytes ("tag@" <> sid) b

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
    tagValue :: MPD.Metadata -> Maybe T.Text
    tagValue tag = case tags !? tag of
      -- Use the first tag if one exists
      Just (val : _) -> Just $ MPD.toText val
      -- If there are 0 values or the tag doesn't exist, return Nothing
      _ -> Nothing

-- ARTWORK HELPERS -------------------------------------------------------------

-- TODO would Data.ByteString.Lazy be faster?
-- Or alternatively, accumulate a list of strict ByteStrings before using `fromChunks`

-- | Given a function to read a chunk of the artwork into a 'ByteString',
-- retrieve the entire artwork
getArtworkBytes
  :: forall es
   . (MPD.EMPD :> es, Error MPD.MPDError :> es, Log :> es)
  => (Integer -> Eff es (Maybe MPD.AlbumArtChunk))
  -- ^ Command to get a chunk of the album art (either readPicture or albumArt)
  -> Eff es (Maybe BS.ByteString)
  -- ^ Full album art as raw bytes
getArtworkBytes getAlbumArtChunk = go BS.empty
  where
    go :: BS.ByteString -> Eff es (Maybe BS.ByteString)
    go acc = do
      -- query mpd for the chunk
      let offset = BS.length acc
      chunk <- getAlbumArtChunk (fromIntegral offset)
      case chunk of
        Nothing -> return Nothing
        Just (MPD.AlbumArtChunk fileSize' _ bytes) -> do
          let fileSize = fromInteger fileSize'
          let chunkSize = BS.length bytes
          -- report progress
          let progress = div (100 * (offset + chunkSize)) fileSize
          logInfo $ T.append "progress: " (T.pack $ show progress) -- TODO might be wise to remove this, since there's a lot of coercions
          -- append to the string and repeat
          let acc' = acc <> bytes
          if offset + chunkSize >= fileSize
            then return $ Just acc'
            else go acc'
-}
