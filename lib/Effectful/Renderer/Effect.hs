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
  loadTexture,
  drawTexture,
) where

import Effectful
import Effectful.TH

import Data.Text qualified as T
import Effectful.Renderer.Types

-- | Interface implemented by the rendering backend.
data Render a :: Effect where
  -- | Clear the window.
  Clear :: Render a m ()
  -- | Present the drawn frame
  Present :: Render a m ()
  -- | Wait until the next frame.
  WaitFrame :: Render a m ()
  -- | Load a texture from a file path, returning an opaque handle to that texture.
  LoadTexture
    :: T.Text
    -- ^ Path of the image to load.
    -> Render a m (Texture a)
  -- | Draw a texture given a handle.
  DrawTexture
    :: Texture a
    -- ^ Texture to draw.
    -> Rect Float
    -- ^ Destination rectangle the texture should be drawn to.
    -> Render a m ()

makeEffect ''Render
