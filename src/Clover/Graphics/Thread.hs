{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Clover.Graphics.Thread
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Clover.Graphics.Thread (runGraphicsThread) where

import Control.Monad (foldM)

import Effectful
import Effectful.Concurrent
import Effectful.Exception
import Effectful.Log as L
import Effectful.Reader.Static

import Effectful.ImageLoader
import Effectful.Renderer
import Util

import Clover.Graphics.Types
import Data.Traversable (mapAccumM)

-- | Dispatch the graphics thread from IOE.
runGraphicsThread
  :: (L.Log :> es, Concurrent :> es, IOE :> es)
  => Eff es ()
runGraphicsThread = do
  L.logTrace_ "Parsing graphics configuration file"
  let configPath = "example-config/ui.json"
  config <- runFileSystem (G.loadConfig configPath) >>= unwrap

  L.logTrace_ "Loading assets from graphics configuration"
  imagesConfig <- runLoadImages $ mapM (loadImagePath >=> unwrap) config

    let runSDL = runSDLRenderer (Vec2 100 100) "clover window"
    runSDL (graphicsThread gConfig' @SDL) >>= unwrap

graphicsThread
  :: forall a es
   . ( Render a :> es
     , LoadImages :> es
     , L.Log :> es
     )
  => Config Image
  -> Eff es ()
graphicsThread imConfig = do
  -- Convert the config from a (Config Image) to a (Config Texture)
  withTexturesConfig @a imConfig $ \texConfig -> do
    L.logTrace_ "Entering loop"
    runReader texConfig $ loop @a

-- | Load all images specified by the config into memory, execute the supplied
-- operation, and finally destroy the loaded textures.
withTexturesConfig
  :: forall a es b
   . Render a :> es
  => Config Image
  -> (Config (Texture a) -> Eff es b)
  -> Eff es b
withTexturesConfig cfg =
  -- TODO does traversable allow higher-order actions? this would hopefully
  -- allow using withTexture instead of load and destroy
  bracket
    (mapM (loadTexture @a) cfg)
    (mapM_ (destroyTexture @a))

loop
  :: forall a es
   . ( Render a :> es
     , L.Log :> es
     , Reader (Config (Texture a)) :> es
     )
  => Eff es ()
loop = do
  L.logTrace_ "Frame"
  clear @a

  -- Draw the background
  bg <- asks cfgBackground
  drawElement @a (Element (Vec2 0 0) (WTexture bg))

  -- Draw the UI elements
  elements <- asks cfgElements
  mapM_ (drawElement @a) elements

  -- Present the frame and loop
  present @a
  waitFrame @a
  loop @a

drawElement
  :: forall a es
   . (Render a :> es, L.Log :> es)
  => Element (Texture a)
  -> Eff es ()
drawElement (Element posn WAlbumArt) = L.logAttention_ "WAlbumArt UNIMPLEMENTED"
drawElement (Element posn (WTexture tex)) = drawTexture tex posn
drawElement (Element posn (WButton tex)) = drawTexture tex posn

{-

-- | Encapsulate the application logic with window and renderer
runApp :: SDLWindow -> SDLRenderer -> IO ()
runApp win renderer = do
  startTime <- sdlGetPerformanceCounter
  freq <- sdlGetPerformanceFrequency
  deltaTimeRef <- newIORef 0.0 -- Will store delta time in seconds
  shouldQuitRef <- newIORef False

  -- Get the current album artwork as a surface
  mpdResult <- MPD.withMPD_ (Just "/tmp/mpd_socket") Nothing $ do
    maybeSong <- currentSongInfo
    let songInfo = maybe "no song playing" show maybeSong
    liftIO $ print $ "song: " ++ songInfo
    song <- case maybeSong of
      Nothing -> liftIO $ exitErr "no song, quitting"
      Just s -> return s
    MPD.binaryLimit 500000
    getArtworkSurface (filePath song)

  albumArtSurf <- (try >=> try) mpdResult -- HACK
  Just tex <- sdlCreateTextureFromSurface renderer albumArtSurf

  -- window shape stuff
  Just im <- sdlLoadBMP "data/circle.bmp"
  -- Just tex <- sdlCreateTextureFromSurface renderer im
  -- TODO cleanup (sdlQuit and destroy resources) if these fail

  -- _ <- sdlSetWindowShape win im

  eventLoop
    win
    renderer
    startTime
    freq
    deltaTimeRef
    shouldQuitRef
    keyStates
    tex

  -- Cleanup (happens after eventLoop finishes)
  sdlLog "Destroying renderer..."
  sdlDestroyRenderer renderer
  sdlLog "Renderer destroyed."
  sdlLog "Destroying window..."
  sdlDestroyWindow win
  sdlLog "Window destroyed."

-- | Main event loop
eventLoop
  :: SDLWindow
  -> SDLRenderer
  -> Word64
  -> Word64
  -> IORef Double
  -> IORef SDLFPoint
  -> IORef Bool
  -> SDLTexture
  -> IO ()
eventLoop window renderer lastTime freq deltaTimeRef shouldQuitRef im = do
  currentTime <- sdlGetPerformanceCounter
  let deltaTimeInSeconds = fromIntegral (currentTime - lastTime) / fromIntegral freq
  writeIORef deltaTimeRef deltaTimeInSeconds -- Store delta time in seconds

  -- Event handling: Process all pending events for this frame
  sdlPumpEvents
  processEvents shouldQuitRef keyStates -- This will handle multiple events
  shouldQuit <- readIORef shouldQuitRef
  unless shouldQuit $ do
    threadDelay 100000

    -- Render the scene
    renderFrame renderer rectPosRef im

    -- Continue loop
    eventLoop
      window
      renderer
      currentTime
      freq
      deltaTimeRef
      rectPosRef
      shouldQuitRef
      keyStates
      im

-- | Process all pending events from the queue for the current frame
processEvents :: IORef Bool -> IO ()
processEvents shouldQuitRef = do
  maybeEvent <- sdlPollEvent
  case maybeEvent of
    Nothing -> return () -- No more events in queue for this frame
    Just event -> do
      -- Handle the current event
      quitSignalFromEvent <- handleSingleEvent event -- Renamed from handleEvent to avoid clash
      when quitSignalFromEvent $ writeIORef shouldQuitRef True

      -- Check if we should continue processing events (e.g., if quit wasn't signaled)
      currentQuitState <- readIORef shouldQuitRef
      unless currentQuitState $
        processEvents shouldQuitRef -- Recursively process next event

-- | Handle a single SDL event, updating key states. Returns True if this event signals a quit.
handleSingleEvent :: SDLEvent -> IO Bool
handleSingleEvent event = case event of
  SDLEventQuit _ -> do
    sdlLog "Quit event received."
    return True
  SDLEventKeyboard ke -> do
    let scancode = sdlKeyboardScancode ke
    let isKeyDown = sdlKeyboardDown ke
    let eventType = sdlKeyboardType ke
    let isRepeat = sdlKeyboardRepeat ke

    sdlLog $
      printf
        "Keyboard Event: Type: %s, Scancode: %s, isKeyDown: %s, Repeat: %s"
        (show eventType)
        (show scancode)
        (show isKeyDown)
        (show isRepeat)

    -- Update IORefs based on key state
    case scancode of
      SDL_SCANCODE_Q ->
        if isKeyDown
          then do
            -- Quit only on Q press
            sdlLog "Q pressed, signaling quit."
            return True
          else
            return False
      _ -> return False -- Other scancodes don't signal quit by default
  _ -> return False -- Other event types don't signal quit by default

artwork fetchers ------------------------------------------------------------

TODO use bilinearResample to scale bitmaps to the same size??

-- | Get the album artwork of the song at the given uri as a SDL surface
--
-- Returns an error if failed to allocate the surface
getArtworkSurface
  :: (MonadBackend e m, MonadIO m)
  => TrackID m
  -> m (Either String (Ptr SDLSurface))
getArtworkSurface trackId = do
  bmp <- getArtwork trackId
  maybeSurf <- liftIO $ toSurface bmp
  return $ case maybeSurf of
    Nothing -> Left "could not load surface"
    Just surf -> return surf

-}
