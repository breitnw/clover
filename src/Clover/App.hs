{-# LANGUAGE AllowAmbiguousTypes #-}

module Clover.App where

-- TODO can maybe just check the first chunk of the album art against some hash
-- to see if we already have it cached

import Control.Concurrent (threadDelay)
import Control.Monad
import Control.Monad.Error.Class
import Control.Monad.Trans

import qualified Data.ByteString as BS
import Data.IORef
import Data.Map
import Data.Maybe (fromMaybe)
import Data.Word (Word64)

import System.Exit
import System.IO

import Foreign.Ptr

import Text.Printf (printf)

-- Libraries

import Clover.App.Monad (App)
import Clover.Backend.Class
import qualified Codec.Image.STB as STB
import qualified Data.Bitmap as BMP
import GHC.Base (List)
import qualified Network.MPD as MPD
import SDL3 hiding (offset)

-- artwork fetchers ------------------------------------------------------------

-- TODO use bilinearResample to scale bitmaps to the same size??

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

-- misc error helpers ----------------------------------------------------------

exitErr :: Show a => a -> IO b
exitErr err = do
  hPutStrLn stderr ("FATAL: " ++ show err)
  exitFailure

try :: Show a => Either a b -> IO b
try = either exitErr return

try_ :: Show a => Either a b -> IO ()
try_ = void . try

-- app logic -------------------------------------------------------------------

-- | Initialize and run the application
main :: IO ()
main = do
  -- Initialize SDL (Events are implicitly initialized by Video, but explicit is fine)
  initSuccess <- sdlInit [SDL_INIT_VIDEO, SDL_INIT_EVENTS]
  unless initSuccess $ do
    sdlLog "Failed to initialize SDL!"
    exitFailure

  -- Create a window
  window <-
    sdlCreateWindow "clover" 400 400 [SDL_WINDOW_TRANSPARENT, SDL_WINDOW_BORDERLESS]
  case window of
    Nothing -> do
      sdlLog "Failed to create window!"
      sdlQuit
      exitFailure
    Just win -> do
      renderer <- sdlCreateRenderer win Nothing
      case renderer of
        Nothing -> do
          sdlLog "Failed to create default renderer!"
          err <- sdlGetError
          sdlLog $ "SDL Error: " ++ err
          sdlDestroyWindow win
          sdlQuit
          exitFailure
        Just ren -> do
          mRendererName <- sdlGetRendererName ren
          sdlLog $ "Created renderer: " ++ fromMaybe "Unknown" mRendererName
          runApp win ren -- Pass window and renderer to runApp
  sdlLog "Shutting down SDL..."
  sdlQuit
  exitSuccess

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

-- | Render a single frame
renderFrame :: SDLRenderer -> IORef SDLFPoint -> SDLTexture -> IO ()
renderFrame renderer rectPosRef tex = do
  -- 1. Set draw color to clear color (e.g., dark blue) and clear
  _ <- sdlSetRenderDrawColor renderer 32 32 64 255
  clearSuccess <- sdlRenderClear renderer
  unless clearSuccess $ sdlLog "Warning: Failed to clear renderer"

  _ <- sdlRenderTexture renderer tex Nothing Nothing

  -- 6. Present the rendered frame
  presentSuccess <- sdlRenderPresent renderer
  unless presentSuccess $ do
    err <- sdlGetError
    sdlLog $ "Warning: Failed to present renderer: " ++ err
