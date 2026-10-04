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
  destroyTexture,
  drawTexture,
) where

import Effectful
import Effectful.TH

import Effectful.ImageLoader.Types
import Effectful.Renderer.Types

-- | Interface implemented by the rendering backend.
data Render a :: Effect where
  -- | Clear the window.
  Clear :: Render a m ()
  -- | Present the drawn frame
  Present :: Render a m ()
  -- | Wait until the next frame.
  WaitFrame :: Render a m ()
  -- | Load a texture into memory, returning an opaque handle to that texture.
  LoadTexture :: Image -> Render a m (Texture a)
  -- | Destroy a texture given its handle. The handle will become invalid.
  DestroyTexture :: Texture a -> Render a m ()
  -- | Draw a texture given a handle.
  DrawTexture :: Texture a -> Vec2 Int -> Render a m ()

makeEffect ''Render
