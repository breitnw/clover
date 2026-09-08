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
  withSDLRenderer,
) where

import Control.Monad (unless)
import Foreign.Ptr (Ptr)

import Codec.Image.STB qualified as STB
import Data.Bitmap qualified as BMP
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Dispatch.Dynamic
import Effectful.Error.Static
import Effectful.Exception
import Effectful.Log qualified as L
import Effectful.Reader.Static
import SDL3 qualified as SDL

import Effectful.Renderer.Effect
import Effectful.Renderer.Types
import Foreign (castPtr)

-- EFFECT HANDLER --------------------------------------------------------------

-- | An empty type representing the SDL render backend.
data SDL

newtype instance Texture SDL = Texture SDL.SDLTexture

-- | The resources available when inside a SDL window context.
data SDLContext = SDLContext
  { scWindow :: SDL.SDLWindow
  , scRenderer :: SDL.SDLRenderer
  }

-- TODO require Fail in es?
withSDLRenderer
  :: forall es a
   . (IOE :> es, L.Log :> es, Concurrent :> es)
  => Vec2 Int
  -- ^ The size of the window to create.
  -> String
  -- ^ The name of the window.
  -> Eff (Render SDL : es) a
  -- ^ The effect to run.
  -> Eff es (Either T.Text a)
withSDLRenderer (Vec2 width height) title = reinterpret_ (runErrorNoCallStack . runSDL) $ \case
  Clear -> clear'
  WaitFrame -> waitFrame'
  Present -> present'
  LoadTexture img -> loadTexture' img
  DrawTexture tex pos -> drawTexture' tex pos
  where
    runSDL
      :: Eff (Reader SDLContext : Error T.Text : es) a
      -> Eff (Error T.Text : es) a
    runSDL eff = do
      bracket_ openSDL closeSDL $ do
        bracket openWindow closeWindow $ \win -> do
          bracket (openRenderer win) closeRenderer $ \ren -> do
            runReader (SDLContext win ren) eff

    -- Open the SDL context.
    openSDL = do
      L.logTrace_ "Acquiring SDL context"
      initSuccess <- liftIO $ SDL.sdlInit [SDL.SDL_INIT_VIDEO, SDL.SDL_INIT_EVENTS]
      -- TODO does throwError still trigger the final computation of bracket?
      unless initSuccess $ throwError @T.Text "Failed to initialize SDL"

    -- Close the SDL context.
    closeSDL = do
      L.logTrace_ "Closing SDL context"
      liftIO SDL.sdlQuit

    -- Open the SDL window.
    openWindow = do
      L.logTrace_ "Initializing SDL window"
      -- let flags = [SDL.SDL_WINDOW_TRANSPARENT, SDL.SDL_WINDOW_BORDERLESS]
      let flags = []
      liftIO (SDL.sdlCreateWindow title width height flags) >>= \case
        Just win -> return win
        Nothing -> throwError @T.Text "Failed to initialize window"

    -- Close the SDL window.
    closeWindow win = do
      L.logTrace_ "Closing SDL window"
      liftIO $ SDL.sdlDestroyWindow win

    -- Open the SDL renderer.
    openRenderer win = do
      L.logTrace_ "Initializing SDL renderer"
      liftIO (SDL.sdlCreateRenderer win Nothing) >>= \case
        Just ren -> return ren
        Nothing -> throwError @T.Text "Failed to initialize renderer"

    -- Close the SDL renderer.
    closeRenderer ren = do
      L.logTrace_ "Closing SDL renderer"
      liftIO $ SDL.sdlDestroyRenderer ren

clear'
  :: ( Reader SDLContext :> es
     , L.Log :> es
     , IOE :> es
     )
  => Eff es ()
clear' = do
  ren <- asks scRenderer
  _ <- liftIO $ SDL.sdlSetRenderDrawColor ren 32 32 64 255
  result <- liftIO $ SDL.sdlRenderClear ren
  unless result $ warn "SDL failed to clear"

-- TODO check out different options for concurrency, there might be a better way
-- to utilize Concurrent effect here
waitFrame' :: Concurrent :> es => Eff es ()
waitFrame' = threadDelay 1000000

present'
  :: ( Reader SDLContext :> es
     , L.Log :> es
     , IOE :> es
     )
  => Eff es ()
present' = do
  ren <- asks scRenderer
  result <- liftIO $ SDL.sdlRenderPresent ren
  unless result $ warn "SDL failed to present frame"

loadTexture'
  :: ( Reader SDLContext :> es
     , L.Log :> es
     , Error T.Text :> es
     , IOE :> es
     )
  => STB.Image
  -> Eff es (Texture SDL)
loadTexture' im = do
  ren <- asks scRenderer
  bracket openSurface closeSurface $ \surf -> do
    liftIO (SDL.sdlCreateTextureFromSurface ren surf) >>= \case
      Nothing -> throwError @T.Text "Failed to create texture from surface"
      Just tex -> return $ Texture tex
  where
    -- Create a surface from 'im'.
    openSurface = do
      -- TODO add surface name for logging?
      L.logTrace_ "Creating surface"
      liftIO (createSurfaceFromImage im) >>= \case
        Nothing -> throwError @T.Text "Failed to create surface from image"
        Just surf -> return surf

    -- Destroy the provided surface.
    closeSurface surf = do
      -- TODO add surface name for logging?
      L.logTrace_ "Destroying surface"
      liftIO $ SDL.sdlDestroySurface surf

drawTexture'
  :: (Reader SDLContext :> es, L.Log :> es, IOE :> es)
  => Texture SDL
  -> Vec2 Int
  -> Eff es ()
drawTexture' (Texture tex) (Vec2 x y) = do
  -- TODO this ignores x and y right now
  ren <- asks scRenderer
  result <- liftIO $ SDL.sdlRenderTexture ren tex Nothing Nothing
  unless result $ warn "SDL failed to render texture"

-- HELPERS ---------------------------------------------------------------------

-- | Log a message as a warning
warn :: L.Log :> es => T.Text -> Eff es ()
warn msg = L.logAttention_ (T.append "[WARNING] " msg)

-- | Convert an STB image to an SDL surface
--
-- based on https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L337
createSurfaceFromImage :: STB.Image -> IO (Maybe (Ptr SDL.SDLSurface))
createSurfaceFromImage bmp = BMP.withBitmap bmp go
  where
    go (w, h) nchn _padding ptr =
      SDL.sdlCreateSurfaceFrom
        (fromIntegral w)
        (fromIntegral h)
        format
        (castPtr ptr)
        (fromIntegral pitch)
      where
        format = case nchn of
          3 -> SDL.SDL_PIXELFORMAT_RGB24
          4 -> SDL.SDL_PIXELFORMAT_RGBA32
          _ -> SDL.SDL_PIXELFORMAT_RGB24 -- TODO MAKE UNREACHABLE
        pitch = nchn * w
