{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effectful.MusicPlayer.Async.Handler.MPD
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.MusicPlayer.Async.Handler.MPD (
  runMPDMusicPlayerAsync,
) where

import Control.Monad (forM_)
import Data.Maybe (fromMaybe)

-- TODO strict MVar?

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent.Async
import Effectful.Concurrent.MVar
import Effectful.Dispatch.Dynamic
import Effectful.Error.Static
import Effectful.Reader.Static
import Effectful.State.Static.Local
import TextShow qualified as T

import Effectful.Concurrent
import Effectful.Exception
import Effectful.Logger
import Effectful.MusicPlayer.Async.Effect
import Effectful.MusicPlayer.Sync qualified as MPS
import Effectful.MusicPlayer.Sync.Handler.MPD qualified as MPS
import Effectful.MusicPlayer.Types
import Effectful.Renderer
import Effectful.Timer

data MPDLocalState a = MPDState
  { mlsArtwork :: Maybe (Texture a)
  , mlsStatus :: PlayerStatus -- there should always be a player status as long as we're done loading
  , mlsCurrentSong :: Maybe Song
  }

-- NOTE DESIGN implementation details should be exposed as little as possible,
-- right? would make it much easier to use
-- whether we have a connection to MPD is an impl. detail, just show that it's
-- stopped to start?
defaultPlayerStatus :: PlayerStatus
defaultPlayerStatus =
  PlayerStatus
    { psState = Stopped
    , psRandom = False
    , psRepeat = False
    , psConsume = ConsumeOff
    , psSingle = SingleOff
    , psProgress = 0
    , psTimestamp = 0
    }

defaultMPDLocalState :: MPDLocalState a
defaultMPDLocalState =
  MPDState
    { mlsArtwork = Nothing
    , mlsStatus = defaultPlayerStatus
    , mlsCurrentSong = Nothing
    }

data MPDSharedState = MPDSharedState
  { mssArtwork :: MVar (Maybe BS.ByteString)
  , mssStatus :: MVar PlayerStatus
  , mssCurrentSong :: MVar (Maybe Song)
  }

runMPDMusicPlayerAsync
  :: forall b a es
   . ( IOE :> es
     , Log :> es
     , Concurrent :> es
     , Render b :> es
     , Time :> es
     )
  => MPS.MPDConfig
  -> Eff (PlayMusicAsync b : es) a
  -> Eff es a
runMPDMusicPlayerAsync config =
  -- TODO set password
  reinterpret_ runWithMPDThread $ \case
    CurrentSong -> currentSong' @b
    CurrentArtwork -> currentArtwork' @b
    CurrentStatus -> currentStatus' @b
    SendCommand cmd -> sendCommand' @b cmd
  where
    runWithMPDThread
      :: Eff (State (MPDLocalState b) : Reader MPDSharedState : es) c
      -> Eff es c
    runWithMPDThread op = do
      defaultArtwork <- newEmptyMVar
      defaultStatus <- newEmptyMVar
      defaultCurrentSong <- newEmptyMVar
      let defaultSyncState = MPDSharedState defaultArtwork defaultStatus defaultCurrentSong
      runReader defaultSyncState $ do
        -- res <- race (runMusicPlayerForever config) $ do
        --   evalState defaultMPDLocalState op
        -- case res of
        --   Left () -> error "INTERNAL ERROR: Music player thread unexpectedly terminated" -- XXX
        --   Right opResult -> return opResult
        musicPlayerThd <- async $ runMusicPlayerForever config
        result <- evalState defaultMPDLocalState op
        _ <- cancel musicPlayerThd
        -- TODO would be nice to free the texture too
        return result

-- | Run the music player and restart it if the connection is lost
runMusicPlayerForever
  :: ( Reader MPDSharedState :> es
     , IOE :> es
     , Log :> es
     , Concurrent :> es
     , Time :> es
     )
  => MPS.MPDConfig -> Eff es ()
runMusicPlayerForever config = do
  runErrorWith handleServerError $ do
    MPS.runMPDMusicPlayerSync config runMusicPlayer
      `catch` handleClientError
  logInfo "Restarting MPD server..."
  runMusicPlayerForever config
  where
    handleServerError
      :: (Log :> es, IOE :> es)
      => CallStack
      -> MPS.Annotated MPS.MPDServerError
      -> Eff es ()
    handleServerError callStack err = do
      -- it's better to crash here, since we shouldn't ever get a client error
      -- at this point (it should be handled in the monad, since it's non-fatal)
      -- TODO does handling in the monad even work?
      -- TODO actually handle all errors runMusicPlayer
      logError $ "Unhandled MPD server error (ACK): " <> T.showt err
      logError $ T.pack $ show callStack
      logError "Aborting!"
      throwIO err
    handleClientError
      :: (Log :> es, IOE :> es)
      => MPS.Annotated MPS.MPDClientError -> Eff es ()
    handleClientError err = do
      logError $ "Got MPD client error: " <> T.showt err

-- TODO XXX DON'T LOAD ARTWORK ALL AT ONCE!! PLEASE
-- (fine for now tho)
loadArtworkFully
  :: MPS.PlayMusicSync :> es => SongID -> Eff es (Maybe BS.ByteString)
loadArtworkFully sid = do
  artwork <- MPS.loadArtwork sid
  case artwork of
    Nothing -> return Nothing
    Just (Done a) -> return (Just a)
    Just Waiting -> loadArtworkFully sid

-- | Run the music player normally
runMusicPlayer
  :: ( Reader MPDSharedState :> es
     , MPS.PlayMusicSync :> es
     , Concurrent :> es
     , Log :> es
     )
  => Eff es ()
runMusicPlayer = do
  currentSongMVar <- asks mssCurrentSong
  artworkMVar <- asks mssArtwork
  statusMVar <- asks mssStatus

  -- TODO want to handle client errors in here
  -- Update player state [TODO: unless there is a command to send]
  newSong <- MPS.currentSong
  lastSong <- tryReadMVar currentSongMVar
  case (lastSong, newSong) of
    -- if the songs are both Nothing or their IDs are equal, don't update
    (Just Nothing, Nothing) -> return ()
    (Just (Just ls), Just ns) | sgID ls == sgID ns -> return ()
    -- otherwise, we need to update
    (_, Nothing) -> do
      _ <- tryTakeMVar currentSongMVar
      _ <- tryPutMVar currentSongMVar Nothing
      return ()
    (_, Just ns) -> do
      _ <- tryTakeMVar currentSongMVar
      _ <- tryPutMVar currentSongMVar (Just ns)
      -- we have a song, so try to load its artwork
      newArtwork <- loadArtworkFully (sgID ns)
      _ <- tryTakeMVar artworkMVar
      _ <- tryPutMVar artworkMVar newArtwork
      return ()

  -- Update status
  -- This tryTake/tryPut nonsense kinda sucks, but I'd prefer to not run into
  -- any deadlocks. If something gets put in the mVar in the time between the
  -- tryTake and tryPut (which should in theory never happen), just let that
  -- be the canonical value and carry on, it's not that deep bro
  newStatus <- MPS.currentStatus
  _ <- tryTakeMVar statusMVar
  _ <- tryPutMVar statusMVar newStatus

  let infinity = 1 / 0
      currentSongDuration = maybe infinity (fromMaybe infinity . sgDuration) newSong
      timeLeft = currentSongDuration - psProgress newStatus

  threadDelay . truncate $ (min (timeLeft + 0.05) 5.0 * 1000000)
  runMusicPlayer

-- TODO
-- this would be much simpler if we just had 3 threads (commands, artwork, status)
-- and used a mutex with the connection...
-- but that might not be possible atp
-- could just have a lock without any data tho!

-- TODO also the semantics of mvar are confusing when we sometimes (for artwork)
-- expect it to be taken, and other times (for everything else) do not
-- might be better to just hold a local variable for the last song, use
-- everything else as channels

-- TODO -> i think it would be best to always use mvar as a single element
-- channel; only take, no read
currentSong'
  :: forall a es
   . ( Reader MPDSharedState :> es
     , State (MPDLocalState a) :> es
     , Concurrent :> es
     )
  => Eff es (Maybe Song)
-- XXX no reason to add to the state as it stands
-- better to treat the mvar as a channel and take?
currentSong' = do
  curSongMVar <- asks mssCurrentSong
  tryReadMVar curSongMVar >>= \case
    Nothing -> return Nothing -- if there's nothing in the channel, assume no song for now
    Just maybeSong -> return maybeSong

currentArtwork'
  :: forall a es
   . ( Reader MPDSharedState :> es
     , State (MPDLocalState a) :> es
     , Render a :> es
     , Concurrent :> es
     , Log :> es
     )
  => Eff es (Maybe (Texture a))
currentArtwork' = do
  artworkMVar <- asks mssArtwork
  tryTakeMVar artworkMVar >>= \case
    Just newArtwork -> do
      -- free the old texture if one exists
      oldTexture <- gets @(MPDLocalState a) mlsArtwork
      forM_ oldTexture destroyTexture
      -- load the new texture
      newTexture <- case newArtwork of
        Just bytes -> do
          logInfo "Loading new artwork texture"
          Just <$> loadTextureBytes bytes
        Nothing -> return Nothing
      modify $ \s -> s{mlsArtwork = newTexture}
      return newTexture
    Nothing -> gets mlsArtwork

currentStatus'
  :: forall a es
   . ( Reader MPDSharedState :> es
     , State (MPDLocalState a) :> es
     , Concurrent :> es
     , Time :> es
     )
  => Eff es PlayerStatus
currentStatus' = do
  statusMVar <- asks mssStatus
  tryReadMVar statusMVar >>= \case
    Nothing -> return defaultPlayerStatus -- if there's nothing in the channel, just return the default status
    Just status -> do
      currentTime <- getPOSIXTime
      let timeDiff = currentTime - psTimestamp status
      -- TODO should the timestamp be updated too? unclear if this could lead to
      -- confusion, like users seeing that the status is out of date and trying
      -- to get the diff themselves
      -- TODO Might be better to remove the timestamp from the status altogether, store it separately
      return
        status{psProgress = psProgress status + fromRational (toRational timeDiff)}

sendCommand'
  :: forall a es
   . ( Reader MPDSharedState :> es
     , State (MPDLocalState a) :> es
     , Concurrent :> es
     )
  => Command
  -> Eff es ()
sendCommand' cmd = do
  error "unimplemented (sendCommand')"
