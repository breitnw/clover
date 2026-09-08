{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}

module Clover.App (main) where

-- TODO can maybe just check the first chunk of the album art against some hash
-- to see if we already have it cached

import System.Exit (exitFailure, exitSuccess)

import Data.Text qualified as T
import Effectful
import Effectful.Concurrent

import Effectful.ImageLoader
import Effectful.Log qualified as L
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL

-- app logic -------------------------------------------------------------------

printLogMessage :: L.LogMessage -> IO ()
printLogMessage msg = do
  print $ L.showLogMessage Nothing msg

-- | Initialize and run the application
main :: IO ()
main = runEff . runConcurrent $ do
  logger <- liftIO $ L.mkLogger "clover logger" printLogMessage
  L.runLog "clover" logger L.LogTrace $ do
    let runSDL = withSDLRenderer (Vec2 261 261) "clover window"
    appResult <- (runSDL . runConcurrent . runLoadImages) (app @SDL)
    case appResult of
      Right _ -> liftIO exitSuccess
      Left msg -> do
        L.logAttention_ $ T.append "[ERROR] " msg
        liftIO exitFailure

app
  :: forall a es
   . ( Render a :> es
     , LoadImages :> es
     , L.Log :> es
     )
  => Eff es ()
app = do
  loadImagePath "data/noa-small.png" >>= \case
    Right im -> do
      tex <- loadTexture @a im
      L.logTrace_ "Entering loop"
      loop tex
    Left err -> do
      L.logAttention_ (T.pack err)
      return ()

loop
  :: forall a es
   . ( Render a :> es
     , L.Log :> es
     )
  => Texture a
  -> Eff es ()
loop tex = do
  -- TODO somehow free texture on close
  -- TODO associate name with texture
  -- TODO log texture and surface open/close
  L.logTrace_ "Frame"
  clear @a
  drawTexture tex (Vec2 0 0)
  present @a
  waitFrame @a
  loop tex

-- -- | Encapsulate the application logic with window and renderer
-- runApp :: SDLWindow -> SDLRenderer -> IO ()
-- runApp win renderer = do
--   startTime <- sdlGetPerformanceCounter
--   freq <- sdlGetPerformanceFrequency
--   deltaTimeRef <- newIORef 0.0 -- Will store delta time in seconds
--   shouldQuitRef <- newIORef False

--   -- Get the current album artwork as a surface
--   mpdResult <- MPD.withMPD_ (Just "/tmp/mpd_socket") Nothing $ do
--     maybeSong <- currentSongInfo
--     let songInfo = maybe "no song playing" show maybeSong
--     liftIO $ print $ "song: " ++ songInfo
--     song <- case maybeSong of
--       Nothing -> liftIO $ exitErr "no song, quitting"
--       Just s -> return s
--     MPD.binaryLimit 500000
--     getArtworkSurface (filePath song)

--   albumArtSurf <- (try >=> try) mpdResult -- HACK
--   Just tex <- sdlCreateTextureFromSurface renderer albumArtSurf

--   -- window shape stuff
--   Just im <- sdlLoadBMP "data/circle.bmp"
--   -- Just tex <- sdlCreateTextureFromSurface renderer im
--   -- TODO cleanup (sdlQuit and destroy resources) if these fail

--   -- _ <- sdlSetWindowShape win im

--   eventLoop
--     win
--     renderer
--     startTime
--     freq
--     deltaTimeRef
--     shouldQuitRef
--     keyStates
--     tex

--   -- Cleanup (happens after eventLoop finishes)
--   sdlLog "Destroying renderer..."
--   sdlDestroyRenderer renderer
--   sdlLog "Renderer destroyed."
--   sdlLog "Destroying window..."
--   sdlDestroyWindow win
--   sdlLog "Window destroyed."

-- -- | Main event loop
-- eventLoop
--   :: SDLWindow
--   -> SDLRenderer
--   -> Word64
--   -> Word64
--   -> IORef Double
--   -> IORef SDLFPoint
--   -> IORef Bool
--   -> SDLTexture
--   -> IO ()
-- eventLoop window renderer lastTime freq deltaTimeRef shouldQuitRef im = do
--   currentTime <- sdlGetPerformanceCounter
--   let deltaTimeInSeconds = fromIntegral (currentTime - lastTime) / fromIntegral freq
--   writeIORef deltaTimeRef deltaTimeInSeconds -- Store delta time in seconds

--   -- Event handling: Process all pending events for this frame
--   sdlPumpEvents
--   processEvents shouldQuitRef keyStates -- This will handle multiple events
--   shouldQuit <- readIORef shouldQuitRef
--   unless shouldQuit $ do
--     threadDelay 100000

--     -- Render the scene
--     renderFrame renderer rectPosRef im

--     -- Continue loop
--     eventLoop
--       window
--       renderer
--       currentTime
--       freq
--       deltaTimeRef
--       rectPosRef
--       shouldQuitRef
--       keyStates
--       im

-- -- | Process all pending events from the queue for the current frame
-- processEvents :: IORef Bool -> IO ()
-- processEvents shouldQuitRef = do
--   maybeEvent <- sdlPollEvent
--   case maybeEvent of
--     Nothing -> return () -- No more events in queue for this frame
--     Just event -> do
--       -- Handle the current event
--       quitSignalFromEvent <- handleSingleEvent event -- Renamed from handleEvent to avoid clash
--       when quitSignalFromEvent $ writeIORef shouldQuitRef True

--       -- Check if we should continue processing events (e.g., if quit wasn't signaled)
--       currentQuitState <- readIORef shouldQuitRef
--       unless currentQuitState $
--         processEvents shouldQuitRef -- Recursively process next event

-- -- | Handle a single SDL event, updating key states. Returns True if this event signals a quit.
-- handleSingleEvent :: SDLEvent -> IO Bool
-- handleSingleEvent event = case event of
--   SDLEventQuit _ -> do
--     sdlLog "Quit event received."
--     return True
--   SDLEventKeyboard ke -> do
--     let scancode = sdlKeyboardScancode ke
--     let isKeyDown = sdlKeyboardDown ke
--     let eventType = sdlKeyboardType ke
--     let isRepeat = sdlKeyboardRepeat ke

--     sdlLog $
--       printf
--         "Keyboard Event: Type: %s, Scancode: %s, isKeyDown: %s, Repeat: %s"
--         (show eventType)
--         (show scancode)
--         (show isKeyDown)
--         (show isRepeat)

--     -- Update IORefs based on key state
--     case scancode of
--       SDL_SCANCODE_Q ->
--         if isKeyDown
--           then do
--             -- Quit only on Q press
--             sdlLog "Q pressed, signaling quit."
--             return True
--           else
--             return False
--       _ -> return False -- Other scancodes don't signal quit by default
--   _ -> return False -- Other event types don't signal quit by default

-- -- | Render a single frame
-- renderFrame :: SDLRenderer -> IORef SDLFPoint -> SDLTexture -> IO ()
-- renderFrame renderer rectPosRef tex = do
--   -- 1. Set draw color to clear color (e.g., dark blue) and clear
--   _ <- sdlSetRenderDrawColor renderer 32 32 64 255
--   clearSuccess <- sdlRenderClear renderer
--   unless clearSuccess $ sdlLog "Warning: Failed to clear renderer"

--   _ <- sdlRenderTexture renderer tex Nothing Nothing

--   -- 6. Present the rendered frame
--   presentSuccess <- sdlRenderPresent renderer
--   unless presentSuccess $ do
--     err <- sdlGetError
--     sdlLog $ "Warning: Failed to present renderer: " ++ err

-- artwork fetchers ------------------------------------------------------------

-- TODO use bilinearResample to scale bitmaps to the same size??

-- -- | Get the album artwork of the song at the given uri as a SDL surface
-- --
-- -- Returns an error if failed to allocate the surface
-- getArtworkSurface
--   :: (MonadBackend e m, MonadIO m)
--   => TrackID m
--   -> m (Either String (Ptr SDLSurface))
-- getArtworkSurface trackId = do
--   bmp <- getArtwork trackId
--   maybeSurf <- liftIO $ toSurface bmp
--   return $ case maybeSurf of
--     Nothing -> Left "could not load surface"
--     Just surf -> return surf
