{- |
Module      : Effectful.Renderer.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Effect (
  Renderer (..),
  loadTexture,
  drawTexture,
) where

import Codec.Image.STB qualified as STB
import Effectful
import Effectful.Dispatch.Dynamic

import Effectful.Renderer.Types

-- | Interface implemented by the rendering backend.
data Renderer a :: Effect where
  LoadTexture :: RenderBackend a => STB.Image -> Renderer a m (Texture a)
  DrawTexture :: RenderBackend a => (Texture a) -> Coordinate -> Renderer a m ()

type instance DispatchOf (Renderer t) = Dynamic

loadTexture
  :: (RenderBackend a, Renderer a :> es)
  => STB.Image
  -> Eff es (Texture a)
loadTexture = send . LoadTexture

drawTexture
  :: (RenderBackend a, Renderer a :> es)
  => Texture a
  -> Coordinate
  -> Eff es ()
drawTexture tex coord = send $ DrawTexture tex coord
