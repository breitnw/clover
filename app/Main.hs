module Main where

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
import qualified Codec.Image.STB as STB
import qualified Data.Bitmap as BMP
import qualified Network.MPD as MPD
import SDL3 hiding (offset)

-- type declarations for rendering ---------------------------------------------

-- Key state IORefs type alias for clarity
type KeyStates = (IORef Bool, IORef Bool, IORef Bool, IORef Bool) -- Up, Down, Left, Right

-- song fetchers ---------------------------------------------------------------

data Song = Song
  { title :: String
  , artist :: String
  , album :: String
  , filePath :: MPD.Path
  }
  deriving (Show)

toSongWithPlaceholders :: MPD.Song -> Song
toSongWithPlaceholders s =
  Song
    { title = getTagStr MPD.Title "Unknown Title"
    , artist = getTagStr MPD.Artist "Unknown Artist"
    , album = getTagStr MPD.Album "Unknown Artist"
    , filePath = MPD.sgFilePath s
    }
  where
    tags = MPD.sgTags s
    getTagStr :: MPD.Metadata -> String -> String
    getTagStr tag defaultStr =
      maybe
        defaultStr
        (MPD.toString . head)
        (tags !? tag)

currentSongInfo :: MPD.MPD (Maybe Song)
currentSongInfo = fmap toSongWithPlaceholders <$> MPD.currentSong

-- artwork fetchers ------------------------------------------------------------

-- TODO make this an ExceptT to collect user errors, display later?
-- depends on whether server should die if there is an unexpected error

-- | Get the album artwork of the song at the given uri as raw bytes
getArtwork :: MPD.Path -> MPD.MPD (Either String BS.ByteString)
getArtwork path = (Right <$> go BS.empty path) `catchError` handler
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

-- | Convert an STB image to an SDL surface
toSurface :: STB.Image -> IO (Maybe (Ptr SDLSurface))
toSurface bmp = BMP.withBitmap bmp go
  where
    go (w, h) nchn _padding ptr =
      sdlCreateSurfaceFrom
        (fromIntegral w)
        (fromIntegral h)
        format
        (castPtr ptr)
        (fromIntegral pitch)
      where
        format = case nchn of
          3 -> SDL_PIXELFORMAT_RGB24
          4 -> SDL_PIXELFORMAT_RGBA32
          _ -> SDL_PIXELFORMAT_RGB24 -- TODO MAKE UNREACHABLE
        pitch = nchn * w

-- TODO use bilinearResample to scale bitmaps to the same size??

-- | Get the album artwork of the song at the given uri as a SDL surface
getArtworkSurface :: MPD.Path -> MPD.MPD (Either String (Ptr SDLSurface))
getArtworkSurface uri = do
  bmp' <- getArtworkBitmap uri
  case bmp' of
    Left err -> return $ Left err
    Right bmp -> liftIO $ do
      maybeSurf <- toSurface bmp
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
  rectPosRef <- newIORef (SDLFPoint 100 100)
  shouldQuitRef <- newIORef False

  -- Create IORefs for key states
  upPressedRef <- newIORef False
  downPressedRef <- newIORef False
  leftPressedRef <- newIORef False
  rightPressedRef <- newIORef False
  let keyStates = (upPressedRef, downPressedRef, leftPressedRef, rightPressedRef)

  theme <- sdlGetSystemTheme
  sdlLog $ "theme: " ++ show theme

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

  _ <- sdlSetWindowShape win im

  eventLoop
    win
    renderer
    startTime
    freq
    deltaTimeRef
    rectPosRef
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
  -> KeyStates
  -> SDLTexture
  -> IO ()
eventLoop window renderer lastTime freq deltaTimeRef rectPosRef shouldQuitRef keyStates im = do
  currentTime <- sdlGetPerformanceCounter
  let deltaTimeInSeconds = fromIntegral (currentTime - lastTime) / fromIntegral freq
  writeIORef deltaTimeRef deltaTimeInSeconds -- Store delta time in seconds

  -- Event handling: Process all pending events for this frame
  sdlPumpEvents
  processEvents shouldQuitRef keyStates -- This will handle multiple events
  shouldQuit <- readIORef shouldQuitRef
  unless shouldQuit $ do
    threadDelay 100000

    -- Update game logic based on current key states and delta time
    updateGameLogic rectPosRef deltaTimeRef keyStates

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
processEvents :: IORef Bool -> KeyStates -> IO ()
processEvents shouldQuitRef keyStates = do
  maybeEvent <- sdlPollEvent
  case maybeEvent of
    Nothing -> return () -- No more events in queue for this frame
    Just event -> do
      -- Handle the current event
      quitSignalFromEvent <- handleSingleEvent event keyStates -- Renamed from handleEvent to avoid clash
      when quitSignalFromEvent $ writeIORef shouldQuitRef True

      -- Check if we should continue processing events (e.g., if quit wasn't signaled)
      currentQuitState <- readIORef shouldQuitRef
      unless currentQuitState $
        processEvents shouldQuitRef keyStates -- Recursively process next event

-- | Handle a single SDL event, updating key states. Returns True if this event signals a quit.
handleSingleEvent :: SDLEvent -> KeyStates -> IO Bool
handleSingleEvent event (upRef, downRef, leftRef, rightRef) = case event of
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
      SDL_SCANCODE_UP -> writeIORef upRef isKeyDown >> return False
      SDL_SCANCODE_DOWN -> writeIORef downRef isKeyDown >> return False
      SDL_SCANCODE_LEFT -> writeIORef leftRef isKeyDown >> return False
      SDL_SCANCODE_RIGHT -> writeIORef rightRef isKeyDown >> return False
      _ -> return False -- Other scancodes don't signal quit by default
  _ -> return False -- Other event types don't signal quit by default

-- | Update game state (like rectangle position) based on current input states and delta time
updateGameLogic :: IORef SDLFPoint -> IORef Double -> KeyStates -> IO ()
updateGameLogic rectPosRef deltaTimeRef (upRef, downRef, leftRef, rightRef) = do
  dtSec <- readIORef deltaTimeRef -- Delta time of the frame in seconds
  let moveSpeed = 200.0 -- Pixels per second
  let moveAmount = realToFrac (moveSpeed * dtSec)

  -- Read current key states
  up <- readIORef upRef
  down <- readIORef downRef
  left <- readIORef leftRef
  right <- readIORef rightRef

  -- Optional: Log states if debugging movement
  -- sdlLog $ printf "updateGameLogic: up:%s, down:%s, left:%s, right:%s, dt:%.4fs, move:%.3f"
  --                 (show up) (show down) (show left) (show right) dtSec moveAmount

  SDLFPoint currentX currentY <- readIORef rectPosRef
  let newX
        | left = currentX - moveAmount
        | right = currentX + moveAmount
        | otherwise = currentX
  let newY
        | up = currentY - moveAmount
        | down = currentY + moveAmount
        | otherwise = currentY

  when (newX /= currentX || newY /= currentY) $
    writeIORef rectPosRef (SDLFPoint newX newY)

-- | Render a single frame
renderFrame :: SDLRenderer -> IORef SDLFPoint -> SDLTexture -> IO ()
renderFrame renderer rectPosRef tex = do
  -- 1. Set draw color to clear color (e.g., dark blue) and clear
  _ <- sdlSetRenderDrawColor renderer 32 32 64 255
  clearSuccess <- sdlRenderClear renderer
  unless clearSuccess $ sdlLog "Warning: Failed to clear renderer"

  -- 2. Set draw color for rectangle (e.g., yellow)
  _ <- sdlSetRenderDrawColor renderer 255 255 0 255

  -- 3. Get current rectangle position
  (SDLFPoint x y) <- readIORef rectPosRef

  -- 4. Define rectangle geometry
  let rect = SDLFRect x y 50 50 -- x, y, width, height

  -- 5. Draw the filled rectangle
  fillRectSuccess <- sdlRenderFillRect renderer (Just rect)
  unless fillRectSuccess $ sdlLog "Warning: Failed to draw filled rect"

  _ <- sdlRenderTexture renderer tex Nothing Nothing

  -- 6. Present the rendered frame
  presentSuccess <- sdlRenderPresent renderer
  unless presentSuccess $ do
    err <- sdlGetError
    sdlLog $ "Warning: Failed to present renderer: " ++ err

-- Helper function to print subsystem names
-- printSubsystem :: SDLInitFlags -> IO ()
-- printSubsystem flag =
--   sdlLog $
--     "  - " ++ case flag of
--       SDL_INIT_AUDIO -> "Audio"
--       SDL_INIT_VIDEO -> "Video"
--       SDL_INIT_JOYSTICK -> "Joystick"
--       SDL_INIT_HAPTIC -> "Haptic"
--       SDL_INIT_GAMEPAD -> "Gamepad"
--       SDL_INIT_EVENTS -> "Events"
--       SDL_INIT_SENSOR -> "Sensor"
--       SDL_INIT_CAMERA -> "Camera"
--       _ -> "Unknown subsystem"
