{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

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
import Data.Text qualified as T
import Foreign (
  Bits (..),
  Ptr,
  maybeWith,
  nullPtr,
  toBool,
  with,
 )
import Foreign.C (CBool, CInt)
import Foreign.C.ConstPtr (ConstPtr (..))
import System.Exit (exitFailure)

import Effectful ()

import Data.Word
import Foreign.Lib.SDL qualified as F
import Foreign.Lib.SDLImage qualified as F
import Foreign.TH
import Foreign.Util

-- | The type of logging functions.
type LoggingFunc = (CInt -> ConstCString -> ConstCString -> IO ())

-- | Helper to log a message given an SDL logging function.
--
-- Always uses the %s format specifier, since allowing any format string is a
-- security vulnerability.
logMsg :: LoggingFunc -> T.Text -> IO ()
logMsg logFn msg = withConstCString msg $ logFn 0 $(ccstring "%s")

-- Resource allocators and deallocators ----------------------------------------

initSDL :: Word32 -> IO ()
initSDL initFlags = do
  initSuccess <- F.sdlInit initFlags
  unless (toBool initSuccess) $ do
    logMsg F.sdlLogError "Failed to initialize SDL"
    exitFailure
  logMsg F.sdlLogInfo "Successfully initialized SDL!"

quitSDL :: IO ()
quitSDL = do
  logMsg F.sdlLogInfo "Quitting SDL"
  F.sdlQuit

createWindow :: ConstCString -> CInt -> CInt -> Word64 -> IO (Ptr F.SDLWindow)
createWindow title w h flags = do
  win <- F.sdlCreateWindow title w h flags
  when (win == nullPtr) $ do
    logMsg F.sdlLogError "Failed to create window"
    exitFailure
  logMsg F.sdlLogInfo "Successfully created window!"
  return win

destroyWindow :: Ptr F.SDLWindow -> IO ()
destroyWindow win = do
  logMsg F.sdlLogInfo "Destroying window"
  F.sdlDestroyWindow win

createRenderer :: Ptr F.SDLWindow -> ConstCString -> IO (Ptr F.SDLRenderer)
createRenderer win name = do
  ren <- F.sdlCreateRenderer win name
  when (ren == nullPtr) $ do
    logMsg F.sdlLogError "Failed to create renderer"
    exitFailure
  logMsg F.sdlLogInfo "Successfully created renderer!"
  return ren

destroyRenderer :: Ptr F.SDLRenderer -> IO ()
destroyRenderer ren = do
  logMsg F.sdlLogInfo "Destroying renderer"
  F.sdlDestroyRenderer ren

-- Utils -----------------------------------------------------------------------

renderTexture
  :: Ptr F.SDLRenderer
  -> Ptr F.SDLTexture
  -> Maybe F.SDLFRect
  -> Maybe F.SDLFRect
  -> IO CBool
renderTexture ren tex src dst =
  maybeWith with src $ \src' ->
    maybeWith with dst $ \dst' ->
      F.sdlRenderTexture ren tex src' dst'

-- Demo ------------------------------------------------------------------------

main :: IO ()
main = do
  let initFlags = F.SDL_INIT_VIDEO .|. F.SDL_INIT_EVENTS
  let windowFlags = F.SDL_WINDOW_ALWAYS_ON_TOP

  -- Try to initialize SDL
  bracket_ (initSDL initFlags) quitSDL $ do
    _ <-
      F.sdlSetAppMetadataProperty
        F.sdlPropAppMetadataNameString
        $(ccstring "SDL demo")
    -- Try to create the window
    let createWindow' title w h flags = withConstCString title $ \title' -> createWindow title' w h flags
    bracket
      (createWindow' "SDL effect demo" 200 200 windowFlags)
      destroyWindow
      $ \win -> do
        -- Try to create the renderer
        bracket (createRenderer win (ConstPtr nullPtr)) destroyRenderer $ \ren -> do
          -- Finally, the fun part!
          runApp ren
          logMsg F.sdlLogInfo "Done acquiring resources"

    -- verify that the metadata name got set properly
    name <- F.sdlGetAppMetadataProperty F.sdlPropAppMetadataNameString
    F.sdlLogInfo 0 $(ccstring "%s finished running") name

runApp :: Ptr F.SDLRenderer -> IO ()
runApp ren = do
  _ <- F.sdlRenderClear ren

  tex <- F.imgLoadTexture ren $(ccstring "data/image1.jpg")
  when (tex == nullPtr) $ do
    logMsg F.sdlLogError "Failed to load texture"
    exitFailure

  _ <- renderTexture ren tex Nothing Nothing
  _ <- renderTexture ren tex Nothing (Just (F.SDLFRect 20 80 80 80))

  _ <- F.sdlRenderPresent ren
  threadDelay 2000000
  F.sdlDestroyTexture tex
