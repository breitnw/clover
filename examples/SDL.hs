{-# LANGUAGE MagicHash #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Main
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Main where

import Control.Concurrent (threadDelay)
import Control.Exception (bracket, bracket_)
import Control.Monad (unless, when)
import Foreign (Bits (..), Ptr, Word32, Word64, nullPtr)
import Foreign.C (CInt, CString, withCString)
import GHC.Ptr qualified as GHC (Ptr (..)) -- needed for CString literal
import System.Exit (exitFailure)

import Effectful ()

import Effectful.Foreign.SDL
import Foreign.Marshal (toBool)

-- | The type of logging functions.
type LoggingFunc = (CInt -> CString -> CString -> IO ())

-- | Helper to log a message given an SDL logging function.
--
-- Always uses the %s format specifier, since allowing any format string is a
-- security vulnerability.
logMsg :: LoggingFunc -> String -> IO ()
logMsg logFn msg = withCString msg $ logFn 0 (GHC.Ptr "%s"#)

-- Resource allocators and deallocators ----------------------------------------

initSDL :: Word32 -> IO ()
initSDL initFlags = do
  initSuccess <- c_sdlInit initFlags
  unless (toBool initSuccess) $ do
    logMsg c_sdlLogError "Failed to initialize SDL"
    exitFailure
  logMsg c_sdlLogInfo "Successfully initialized SDL!"

quitSDL :: IO ()
quitSDL = do
  logMsg c_sdlLogInfo "Quitting SDL"
  c_sdlQuit

createWindow :: CString -> CInt -> CInt -> Word64 -> IO (Ptr SDLWindow)
createWindow title w h flags = do
  win <- c_sdlCreateWindow title w h flags
  when (win == nullPtr) $ do
    logMsg c_sdlLogError "Failed to create window"
    exitFailure
  logMsg c_sdlLogInfo "Successfully created window!"
  return win

destroyWindow :: Ptr SDLWindow -> IO ()
destroyWindow win = do
  logMsg c_sdlLogInfo "Destroying window"
  c_sdlDestroyWindow win

createRenderer :: Ptr SDLWindow -> CString -> IO (Ptr SDLRenderer)
createRenderer win name = do
  ren <- c_sdlCreateRenderer win name
  when (ren == nullPtr) $ do
    logMsg c_sdlLogError "Failed to create renderer"
    exitFailure
  logMsg c_sdlLogInfo "Successfully created renderer!"
  return ren

destroyRenderer :: Ptr SDLRenderer -> IO ()
destroyRenderer ren = do
  logMsg c_sdlLogInfo "Destroying renderer"
  c_sdlDestroyRenderer ren

-- Demo ------------------------------------------------------------------------

main :: IO ()
main = do
  let initFlags = SDL_INIT_VIDEO .|. SDL_INIT_EVENTS
  let windowFlags = SDL_WINDOW_ALWAYS_ON_TOP

  -- Try to initialize SDL
  bracket_ (initSDL initFlags) quitSDL $ do
    -- Try to create the window
    let createWindow' title w h flags = withCString title $ \title' -> createWindow title' w h flags
    bracket
      (createWindow' "SDL effect demo" 200 200 windowFlags)
      destroyWindow
      $ \win -> do
        -- Try to create the renderer
        bracket (createRenderer win nullPtr) destroyRenderer $ \ren -> do
          -- Finally, the fun part!
          runApp ren
          logMsg c_sdlLogInfo "Done acquiring resources"

runApp :: Ptr SDLRenderer -> IO ()
runApp ren = do
  _ <- c_sdlRenderClear ren
  threadDelay 2000000
