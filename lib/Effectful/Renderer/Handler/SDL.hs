{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effectful.Renderer.Handler.SDL
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Handler.SDL (
  SDL,
  runSDLRenderer,
) where

import Control.Monad (unless)
import Foreign (Bits ((.|.)), Ptr, castPtr, nullPtr, toBool)
import Foreign.C (withCString)
import Foreign.ForeignPtr (ForeignPtr)

import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Dispatch.Dynamic
import Effectful.Exception
import Effectful.Reader.Static

import Effectful.Logger
import Effectful.Renderer.Effect
import Effectful.Renderer.Types
import Foreign.SDL qualified as F

-- TODO it would be nice to use ForeignPtr in this module to take advantage of
-- GC for textures, surfaces, etc
-- Monad can still handle freeing window/renderer

-- EFFECT HANDLER --------------------------------------------------------------

-- | An empty type representing the SDL render backend.
data SDL

-- | A SDL texture comes with a name and data
data instance Texture SDL = Texture ImageMeta (ForeignPtr F.SDLTexture)

-- | The resources available when inside a SDL window context.
data SDLContext = SDLContext
  { scWindow :: Ptr F.SDLWindow
  , scRenderer :: Ptr F.SDLRenderer
  }

newtype SDLException = SDLException T.Text
  deriving (Show)

instance Exception SDLException

runSDLRenderer
  :: forall es a
   . (IOE :> es, Log :> es, Concurrent :> es)
  => Vec2 Int
  -- ^ The size of the window to create.
  -> String
  -- ^ The name of the window.
  -> Eff (Render SDL : es) a
  -- ^ The effect to run.
  -> Eff es a
runSDLRenderer (Vec2 width height) title = reinterpret_ runSDL $ \case
  Clear -> clear'
  WaitFrame -> waitFrame'
  Present -> present'
  LoadTexture img -> loadTexture' img
  DrawTexture tex pos -> drawTexture' tex pos
  where
    runSDL
      :: Eff (Reader SDLContext : es) a
      -> Eff es a
    runSDL eff = do
      bracket_ openSDL closeSDL $ do
        bracket openWindow closeWindow $ \win -> do
          bracket (openRenderer win) closeRenderer $ \ren -> do
            runReader (SDLContext win ren) eff

    -- Open the SDL context.
    openSDL = do
      logInfo "Acquiring SDL context"
      initSuccess <- liftIO $ F.sdlInit (F.SDL_INIT_VIDEO .|. F.SDL_INIT_EVENTS)
      unless (toBool initSuccess) $ throwIO $ SDLException "Failed to initialize SDL"

    -- Close the SDL context.
    closeSDL = do
      logInfo "Closing SDL context"
      liftIO F.sdlQuit

    -- Open the SDL window.
    openWindow = do
      logInfo "Initializing SDL window"
      let flags = F.SDL_WINDOW_TRANSPARENT .|. F.SDL_WINDOW_BORDERLESS
      win <-
        liftIO
          ( withCString title $ \title' ->
              F.sdlCreateWindow title' (fromIntegral width) (fromIntegral height) flags
          )
      if win == nullPtr
        then throwIO $ SDLException "Failed to initialize window"
        else return win

    -- Close the SDL window.
    closeWindow win = do
      logInfo "Closing SDL window"
      liftIO $ F.sdlDestroyWindow win

    -- Open the SDL renderer.
    openRenderer win = do
      logInfo "Initializing SDL renderer"
      ren <- liftIO (F.sdlCreateRenderer win nullPtr)
      if ren == nullPtr
        then throwIO $ SDLException "Failed to initialize renderer"
        else return ren

    -- Close the SDL renderer.
    closeRenderer ren = do
      logInfo "Closing SDL renderer"
      liftIO $ F.sdlDestroyRenderer ren

clear'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => Eff es ()
clear' = do
  ren <- asks scRenderer
  _ <- liftIO $ F.sdlSetRenderDrawColor ren 0 0 0 0
  result <- liftIO $ F.sdlRenderClear ren
  unless (toBool result) $ logWarn "SDL failed to clear"

-- TODO check out different options for concurrency, there might be a better way
-- to utilize Concurrent effect here
waitFrame' :: Concurrent :> es => Eff es ()
waitFrame' = threadDelay 1000000

present'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => Eff es ()
present' = do
  ren <- asks scRenderer
  result <- liftIO $ F.sdlRenderPresent ren
  unless (toBool result) $ logWarn "SDL failed to present frame"

loadTexture'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => Image
  -> Eff es (Texture SDL)
loadTexture' (Image meta im) = do
  ren <- asks scRenderer
  bracket openSurface closeSurface $ \surf -> do
    logInfo $ "Creating texture: " <> imMetaName meta
    tex <- liftIO $ F.sdlCreateTextureFromSurface ren surf
    if tex == nullPtr
      then throwIO $ SDLException "Failed to create texture from surface"
      else do
        foreignPtr <- liftIO $ newForeignPtr _ tex
        return $ Texture meta foreignPtr
  where
    -- Create a surface from 'im'.
    openSurface = do
      logInfo $ "Creating surface: " <> imMetaName meta
      liftIO (createSurfaceFromImage im) >>= \case
        Nothing -> throwIO $ SDLException "Failed to create surface from image"
        Just surf -> return surf

    -- Destroy the provided surface.
    closeSurface surf = do
      logInfo $ "Destroying surface: " <> imMetaName meta
      liftIO $ F.sdlDestroySurface surf

destroyTexture'
  :: (Log :> es, IOE :> es)
  => Texture SDL
  -> Eff es ()
destroyTexture' (Texture meta tex) = do
  logInfo $ "Destroying texture: " <> imMetaName meta
  liftIO $ F.sdlDestroyTexture tex

drawTexture'
  :: (Reader SDLContext :> es, Log :> es, IOE :> es)
  => Texture SDL
  -> Vec2 Int
  -> Eff es ()
drawTexture' (Texture meta tex) (Vec2 x y) = do
  -- TODO this ignores x and y right now
  ren <- asks scRenderer
  result <- liftIO $ sdlRenderTexture ren tex Nothing Nothing
  unless result $
    logWarn $
      "SDL failed to render texture" <> imMetaName meta

-- HELPERS ---------------------------------------------------------------------

-- | Convert an STB image to an SDL surface
--
-- based on https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L337
createSurfaceFromImage :: STB.Image -> IO (Maybe (Ptr F.SDLSurface))
createSurfaceFromImage bmp = BMP.withBitmap bmp go
  where
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    -- TODO MAKE SURE THAT THE IMAGE ISN'T FREED UNTIL CREATING THE TEXTURE
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
