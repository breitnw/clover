{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effectful.Renderer.Handler.SDL
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Handler.SDL (
  withSDLRenderer,
) where

import Control.Monad (unless)
import Foreign.Ptr (Ptr)

import Codec.Image.STB qualified as STB
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Error.Static
import Effectful.Exception
import Effectful.Log qualified as L
import Effectful.Reader.Static
import SDL3 qualified as SDL

import Effectful.Renderer.Effect
import Effectful.Renderer.Types

-- EFFECT HANDLER --------------------------------------------------------------

-- | An empty type representing the SDL render backend.
data SDL

newtype instance Texture SDL = Texture (Ptr SDL.SDLSurface)

-- | The resources available when inside a SDL window context.
data SDLContext = SDLContext
  { scWindow :: SDL.SDLWindow
  , scRenderer :: SDL.SDLRenderer
  }

-- TODO require Fail in es?
withSDLRenderer
  :: forall es a
   . (IOE :> es, L.Log :> es)
  => Vec2 Int
  -- ^ The size of the window to create.
  -> String
  -- ^ The name of the window.
  -> Eff (Render SDL : es) a
  -- ^ The effect to run.
  -> Eff es (Either String a)
withSDLRenderer (Vec2 width height) title = reinterpret_ (runErrorNoCallStack . runSDL) $ \case
  LoadTexture img -> loadTexture' img
  DrawTexture tex pos -> drawTexture' tex pos
  where
    runSDL
      :: Eff (Reader SDLContext : Error String : es) a
      -> Eff (Error String : es) a
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
      unless initSuccess $ throwError @String "Failed to initialize SDL"

    -- Close the SDL context.
    closeSDL = do
      L.logTrace_ "Closing SDL context"
      liftIO SDL.sdlQuit

    -- Open the SDL window.
    openWindow = do
      L.logTrace_ "Initializing SDL window"
      let flags = [SDL.SDL_WINDOW_TRANSPARENT, SDL.SDL_WINDOW_BORDERLESS]
      liftIO (SDL.sdlCreateWindow title width height flags) >>= \case
        Just win -> return win
        Nothing -> throwError @String "Failed to initialize window"

    -- Close the SDL window.
    closeWindow win = do
      L.logTrace_ "Closing SDL window"
      liftIO $ SDL.sdlDestroyWindow win

    -- Open the SDL renderer.
    openRenderer win = do
      L.logTrace_ "Initializing SDL renderer"
      liftIO (SDL.sdlCreateRenderer win Nothing) >>= \case
        Just ren -> return ren
        Nothing -> throwError @String "Failed to initialize renderer"

    -- Close the SDL renderer.
    closeRenderer ren = do
      L.logTrace_ "Closing SDL renderer"
      liftIO $ SDL.sdlDestroyRenderer ren

loadTexture'
  :: (Reader SDLContext :> es, Error String :> es)
  => STB.Image
  -> Eff es (Texture a)
loadTexture' im = throwError @String "unimplemented"

drawTexture'
  :: (Reader SDLContext :> es, Error String :> es)
  => Texture a
  -> Vec2 Int
  -> Eff es ()
drawTexture' tex (Vec2 x y) = throwError @String "unimplemented"

-- CONVERTERS ------------------------------------------------------------------

-- | Convert an STB image to an SDL surface
--
-- based on https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L337

-- toSurface :: STB.Image -> IO (Maybe (Ptr SDLSurface))
-- toSurface bmp = BMP.withBitmap bmp go
--   where
--     go (w, h) nchn _padding ptr =
--       sdlCreateSurfaceFrom
--         (fromIntegral w)
--         (fromIntegral h)
--         format
--         (castPtr ptr)
--         (fromIntegral pitch)
--       where
--         format = case nchn of
--           3 -> SDL_PIXELFORMAT_RGB24
--           4 -> SDL_PIXELFORMAT_RGBA32
--           _ -> SDL_PIXELFORMAT_RGB24 -- TODO MAKE UNREACHABLE
--         pitch = nchn * w
