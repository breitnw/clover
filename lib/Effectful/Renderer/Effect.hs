{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.Renderer.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Effect (
  Render (..),
  clear,
  waitFrame,
  present,
  loadTextureFileEx,
  loadTextureBytesEx,
  loadTextureFile,
  loadTextureBytes,
  destroyTexture,
  drawTexture,
  loadText,
  destroyText,
  drawText,
  setDrawColor,
) where

import Data.ByteString qualified as BS
import Effectful
import Effectful.TH

import Data.Text qualified as T
import Effectful.Renderer.Types
import Util

-- | Interface implemented by the rendering backend.
data Render a :: Effect where
  -- | Clear the window.
  Clear :: Render a m ()
  -- | Present the drawn frame
  Present :: Render a m ()
  -- | Wait until the next frame.
  WaitFrame :: Render a m ()
  -- | Load a texture from a file path, returning an opaque handle to that texture.
  LoadTextureFileEx
    :: TextureOptions
    -- ^ Options for the creation of the texture
    -> Path
    -- ^ Path of the image to load.
    -> Render a m (Texture a)
  -- | Load a texture from a ByteString, returning an opaque handle to that texture.
  LoadTextureBytesEx
    :: TextureOptions
    -- ^ Options for the creation of the texture
    -> BS.ByteString
    -- ^ Contents of the image to load.
    -> Render a m (Texture a)
  DestroyTexture
    :: Texture a
    -- ^ Texture to destroy.
    -> Render a m ()
  -- | Draw a texture given a handle.
  DrawTexture
    :: Texture a
    -- ^ Texture to draw.
    -> Rect Float
    -- ^ Destination rectangle the texture should be drawn to.
    -> Render a m ()
  LoadText :: T.Text -> Color -> Render a m (Text a)
  DestroyText :: Text a -> Render a m ()
  DrawText :: Text a -> Vec2 Float -> Render a m ()
  SetDrawColor :: Color -> Render a m ()

makeEffect ''Render

-- | Version of loadTextureFileEx without options.
loadTextureFile
  :: forall a es. Render a :> es => Path -> Eff es (Texture a)
loadTextureFile = loadTextureFileEx @a defaultTextureOptions

-- | Version of loadTextureBytesEx without options.
loadTextureBytes
  :: forall a es. Render a :> es => BS.ByteString -> Eff es (Texture a)
loadTextureBytes = loadTextureBytesEx @a defaultTextureOptions
