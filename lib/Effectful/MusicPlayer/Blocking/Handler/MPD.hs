{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

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
  -- TODO when ServerError is generalized across backends, no longer need to export this
  -- notably, don't really want to export 'mpdRecoverError'
  module Effectful.MusicPlayer.Blocking.Handler.MPD.Error,
) where

import Control.Monad (unless, when)
import Foreign (
  castPtr,
  copyBytes,
  free,
  fromBool,
  mallocArray,
  peek,
  plusPtr,
  toBool,
 )
import Foreign.C (CBool, CInt, CSize, CStringLen, CUInt)
import Foreign.Ptr (Ptr)

import Data.ByteString qualified as BS
import Data.ByteString.Unsafe qualified as BS
import Data.Text qualified as T
import Data.Text.Read qualified as T
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Error.Static
import Effectful.Exception
import Effectful.Reader.Static
import Effectful.State.Static.Local
import TextShow qualified as T

import Effectful.Logger
import Effectful.MusicPlayer.Blocking
import Effectful.MusicPlayer.Blocking.Handler.MPD.Error
import Foreign.Lib.MPD qualified as F
import Foreign.TH
import Foreign.Util
import Util

-- TODO it would be nice to dynamically change binary limit based on the speed
-- of the last request

-- TODO check something sensible happens if the connection dies before reading
-- artwork (since mpdRunCheck doesn't get run)

-- TODO check what happens if both methods fail (no artwork at all)

-- SUPPORTING TYPES ------------------------------------------------------------

data ArtworkResponse = ArtworkResponse
  { arFileSize :: CUInt
  , arReadSize :: CUInt
  }

type ArtworkFetcher =
  Ptr F.MPDConnection
  -- ^ Current connection to the MPD server.
  -> SongID
  -- ^ URI of the song.
  -> Int
  -- ^ Current offset (into both the remote file and local buffer).
  -> CStringLen
  -- ^ Buffer to read into.
  -> Eff '[Log, Error (Annotated MPDServerError), IOE] (Maybe ArtworkResponse)

-- | A buffer (pointer to allocated memory and size of that memory)
-- type Buffer = (Ptr (), CSize)

-- | Current internal state of artwork fetching process.
data ArtworkState = ArtworkState
  { artworkID :: SongID
  , artworkFetcher :: ArtworkFetcher
  , artworkOffset :: Int
  , artworkBuffer :: CStringLen
  }

-- TODO since MPD is reused in Continuous, might be a better idea to
data MPDConfig = MPDConfig
  { mcHost :: T.Text
  , mcPort :: Maybe Int -- Nothing for default port (using MPD_PORT)
  , mcPassword :: Maybe T.Text -- Nothing for no password
  , mcTimeout :: Maybe Int -- Nothing for default timeout (using MPD_TIMEOUT)
  }

data MPDResources = MPDResources
  { mrConn :: Ptr F.MPDConnection
  , mrArtworkInitBuffer :: CStringLen
  -- ^ Buffer for the first fetch using albumart or readpicture, before we know
  -- the file size of the artwork
  }

-- LOW-LEVEL MEMORY MANAGEMENT -------------------------------------------------

mallocBuffer :: Int -> IO CStringLen
mallocBuffer size = do
  buf <- mallocArray size
  return (buf, size)

freeBuffer :: CStringLen -> IO ()
freeBuffer (buf, _) = free buf

-- | Take the slice of the buffer starting at offset.
-- If offset exceeds the bounds of the buffer, returns an empty buffer
sliceBuffer :: CStringLen -> Int -> CStringLen
sliceBuffer (buf, bufSize) offset =
  if offset < bufSize
    then (plusPtr buf offset, bufSize - offset)
    else (plusPtr buf bufSize, 0)

-- | Copy one buffer into another.
copyBuffer :: CStringLen -> CStringLen -> IO ()
copyBuffer (srcBuf, srcLen) (dstBuf, dstLen) = do
  copyBytes srcBuf dstBuf (min (fromIntegral srcLen) (fromIntegral dstLen))

-- LOW-LEVEL ERROR HANDLING ----------------------------------------------------

-- | Handle all MPD errors (server and client) by calling 'mpdRecoverError'
-- and throwing server errors via the Error effect.
--
-- Prefer 'mpdFail' when it is certain there is an error.
mpdHandleErrors
  :: (IOE :> es, Error (Annotated MPDServerError) :> es)
  => Ptr F.MPDConnection -> Eff es ()
mpdHandleErrors conn = do
  maybeErr <- mpdRecoverError conn
  maybe (return ()) throwError maybeErr

mpdFail
  :: (IOE :> es, Error (Annotated MPDServerError) :> es)
  => Ptr F.MPDConnection -> Eff es a
mpdFail conn = do
  mpdHandleErrors conn
  error "UNREACHABLE: expected an MPD error but got none"

-- | Throw an exception stating that the current response is malformed.
mpdErrorMalformed :: IOE :> es => T.Text -> Eff es a
mpdErrorMalformed msg = throwIO $ Ann msg CMalformed

-- EFFECT HANDLER --------------------------------------------------------------

runMPDMusicPlayerBlocking
  :: forall es a
   . (IOE :> es, Log :> es, Error (Annotated MPDServerError) :> es)
  => MPDConfig
  -> Eff (PlayMusic : es) a
  -> Eff es a
runMPDMusicPlayerBlocking (MPDConfig host port password timeout) =
  -- TODO set password
  reinterpret_ runMPD $ \case
    CurrentSong -> currentSong'
    LoadArtwork songID -> loadArtwork' songID
    SendCommand cmd -> sendCommand' cmd
  where
    runMPD op = bracket openMPD closeMPD $ \conn -> do
      mpdHandleErrors conn
      -- configure the binary limit & allocate the artwork init buffer
      let binaryLimit = 40000
      blResult <- liftIO $ F.mpdRunBinaryLimit conn (fromIntegral binaryLimit)
      unless (toBool blResult) $ mpdFail conn
      logInfo $ "Configured binary limit as " <> T.showt binaryLimit

      bracket (liftIO $ mallocBuffer binaryLimit) (liftIO . freeBuffer) $ \initBuf ->
        -- run the effect with the initialized resources
        runReader (MPDResources conn initBuf) $
          evalState @(Maybe ArtworkState) Nothing op

    -- Open a MPD connection. Only checks for out of memory errors.
    -- Don't want to check for MPD errors yet, otherwise conn will not be freed
    openMPD = do
      logInfo "Opening MPD connection"
      conn <- liftIO $ withCString host $ \hostCStr ->
        F.mpdConnectionNew
          hostCStr
          (maybe 0 fromIntegral port)
          (maybe 0 fromIntegral timeout)
      -- if the connection is NULL, that means there was no memory left
      when (conn == nullPtr) $ throwIO (Ann "Out of memory" COutOfMemory)
      return conn

    -- Close an MPD connection.
    closeMPD :: Ptr F.MPDConnection -> Eff es ()
    closeMPD conn = do
      logInfo "Closing MPD connection"
      liftIO $ F.mpdConnectionFree conn

currentSong'
  :: ( IOE :> es
     , Reader MPDResources :> es
     , Error (Annotated MPDServerError) :> es
     )
  => Eff es (Maybe Song)
currentSong' = do
  conn <- asks mrConn
  bracket (getCurrentSong conn) destroySong $ \maybeSong -> do
    mpdHandleErrors conn
    case maybeSong of
      Nothing -> return Nothing
      Just song -> do
        title <- maybeGetTagText =<< liftIO (F.mpdSongGetTag song F.MPD_TAG_TITLE 0)
        artist <- maybeGetTagText =<< liftIO (F.mpdSongGetTag song F.MPD_TAG_ARTIST 0)
        album <- maybeGetTagText =<< liftIO (F.mpdSongGetTag song F.MPD_TAG_ALBUM 0)
        duration <-
          -- duration of 0 means unknown
          (\i -> if i == 0 then Nothing else Just i)
            . fromIntegral
            <$> liftIO (F.mpdSongGetDurationMs song)
        songID <- SongID <$> (getTagText =<< liftIO (F.mpdSongGetURI song))
        return $ Just (Song title artist album duration songID)
  where
    -- Get current song, or Nothing if there is no song playing
    getCurrentSong = liftIO . fmap nullToNothing . F.mpdRunCurrentSong

    -- Free memory allocated for a song, or pass if the song is Nothing
    destroySong = liftIO . maybe (return ()) F.mpdSongFree

    -- Convert a tag value (constCString) to text.
    getTagText = liftIO . peekCString

    -- Convert a tag value (constCString) to text, or Nothing if null
    maybeGetTagText = traverse getTagText . nullToNothing

-- TODO use Alternative to load artwork until done?
loadArtwork'
  :: forall es
   . ( IOE :> es
     , State (Maybe ArtworkState) :> es
     , Reader MPDResources :> es
     , Log :> es
     , Error (Annotated MPDServerError) :> es
     )
  => SongID
  -> Eff es (Maybe (Status BS.ByteString))
loadArtwork' songID = do
  conn <- asks mrConn
  artworkState <- get
  case artworkState of
    -- outcome 1. We are in the process of fetching the artwork already.
    Just st@(ArtworkState currID fetcher offset buf) | songID == currID -> do
      logInfo $ "Resuming artwork fetch for " <> T.showt songID
      maybeRead <- inject $ fetcher conn songID offset (sliceBuffer buf offset)
      case maybeRead of
        Just (ArtworkResponse _ readSize) -> do
          put $ Just st{artworkOffset = offset + fromIntegral readSize}
          returnStatus
        Nothing -> do
          logWarn "Read chunk size of 0! Trying to continue..." -- TODO should this fail?
          return $ Just Waiting

    -- outcome 2. We are not currently fetching the desired artwork.
    _ -> do
      logInfo $ "Starting artwork fetch for " <> T.showt songID
      -- If we have a current artworkState, free the buffer and clear
      case artworkState of
        Just (ArtworkState (SongID oldSid) _ _ buf) -> do
          logInfo $ "Giving up loading artwork for " <> oldSid
          liftIO $ freeBuffer buf
          put @(Maybe ArtworkState) Nothing
        _ -> return ()

      -- Try to get the artwork from the cache, from albumart, and from
      -- readpicture in that order
      tryCache
        `orElseDo` tryFetcher "albumart" runAlbumArt
        `orElseDo` tryFetcher "readpicture" runReadPicture
  where
    -- Try to get the artwork from the cache.
    tryCache :: Eff es (Maybe (Status BS.ByteString))
    tryCache = do
      logInfo "Trying to fetch artwork from cache"
      -- TODO
      return Nothing

    -- Try to get the artwork from a fetch function.
    tryFetcher :: T.Text -> ArtworkFetcher -> Eff es (Maybe (Status BS.ByteString))
    tryFetcher fetcherName fetcher = do
      MPDResources conn initBuf <- ask
      logInfo $ "Trying fetcher " <> fetcherName
      maybeRead <- inject $ fetcher conn songID 0 initBuf
      case maybeRead of
        Just (ArtworkResponse fileSize readSize) -> do
          logInfo "Fetch successful"
          -- make a buffer with the proper size
          -- TODO XXX FIXME !!!!!!!!!!!!!!!! NOT FREED ON ERROR
          buf <- liftIO $ mallocBuffer (fromIntegral fileSize)
          -- copy the bytes from the first read into the new buffer
          liftIO $ copyBuffer initBuf buf
          -- update the state and return if done
          put $ Just (ArtworkState songID fetcher (fromIntegral readSize) buf)
          returnStatus
        Nothing -> do
          logInfo "Fetch unsuccessful"
          return Nothing

    -- if the buffer is full, pack it as a bytestring and return it
    returnStatus :: Eff es (Maybe (Status BS.ByteString))
    returnStatus = do
      st <- get
      case st of
        Just (ArtworkState _ _ offset buf@(_, bufSize)) ->
          if offset >= bufSize
            then do
              put @(Maybe ArtworkState) Nothing
              -- what a wonderfully unsafe function
              packedBuf <- liftIO $ BS.unsafePackMallocCStringLen buf
              return $ Just (Done packedBuf)
            else return $ Just Waiting
        Nothing -> return Nothing

-- | Artwork fetcher for the albumart method.
runAlbumArt :: ArtworkFetcher
runAlbumArt = runArtworkMethod F.mpdSendAlbumArt F.mpdRecvAlbumArt

-- | Artwork fetcher for the readpicture method.
runReadPicture :: ArtworkFetcher
runReadPicture = runArtworkMethod F.mpdSendReadPicture F.mpdRecvReadPicture

-- | Create an artwork fetcher given the send and recv commands.
-- Reads into the start of the provided buffer.
runArtworkMethod
  :: (Ptr F.MPDConnection -> ConstCString -> CUInt -> IO CBool)
  -> (Ptr F.MPDConnection -> Ptr () -> CSize -> IO CInt)
  -> ArtworkFetcher
runArtworkMethod sendCmd recvCmd conn (SongID uri) offset (buf, bufSize) = do
  -- TODO mpd_run_check?

  -- TODO marshalling the URI every time this function is called kinda sucks
  sendStatus <- liftIO $ withCString uri $ \cUri -> sendCmd conn cUri (fromIntegral offset)
  unless (toBool sendStatus) $ mpdFail conn

  -- recieve and parse the file size
  pair <- liftIO $ F.mpdRecvPairNamed conn $(ccstring "size")
  if pair == nullPtr
    then handleAARecvError >> return Nothing
    else do
      (F.MPDPair _ fileSizeCCStr) <- liftIO $ peek pair
      fileSizeText <- liftIO $ peekCString fileSizeCCStr
      liftIO $ F.mpdReturnPair conn pair
      fileSize <- case T.decimal fileSizeText of
        Left err ->
          mpdErrorMalformed $ "File size could not be parsed as decimal: " <> T.pack err
        Right (val, _) -> return val

      -- recieve the chunk into the buffer
      readSize <- liftIO $ recvCmd conn (castPtr buf) (fromIntegral bufSize)
      if readSize == -1
        then handleAARecvError >> return Nothing
        else do
          -- finalize the request
          finishResult <- liftIO $ F.mpdResponseFinish conn
          unless (toBool finishResult) $ mpdFail conn
          return $ Just (ArtworkResponse fileSize (fromIntegral readSize))
  where
    -- NOTE Overapproximates the outcomes that are interpreted as "no artwork
    -- exists," because I'm lazy and because it doesn't really matter...
    handleAARecvError = do
      maybeErr <- mpdRecoverError conn
      case maybeErr of
        -- for readpicture, `MPD_ERROR_SUCCESS` (with code -1) means no artwork
        Nothing -> return ()
        -- for albumart, `MPD_SERVER_ERROR_NO_EXIST` (with code -1) means no artwork
        Just (Ann _ SNoExist) -> return () -- TODO check some regex on the text?
        -- all other errors are treated as actual failures
        Just e -> throwError e

sendCommand'
  :: ( IOE :> es
     , Reader MPDResources :> es
     , Error (Annotated MPDServerError) :> es
     )
  => Command
  -> Eff es ()
sendCommand' cmd = do
  conn <- asks mrConn
  res <- liftIO $ case cmd of
    Play -> F.mpdRunPlay conn
    Pause -> F.mpdRunPause conn (fromBool True)
    Resume -> F.mpdRunPause conn (fromBool False)
    Next -> F.mpdRunNext conn
    Previous -> F.mpdRunNext conn
  -- TODO failMalformed here too? or get rid of it everywhere
  unless (toBool res) $ mpdFail conn
