{- |
Module      : Effectful.Renderer.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Effect (
  Render (..),
  loadTexture,
  drawTexture,
) where

import Codec.Image.STB qualified as STB
import Effectful
import Effectful.Dispatch.Dynamic

import Effectful.Renderer.Types

-- | Interface implemented by the rendering backend.
data Render a :: Effect where
  LoadTexture :: STB.Image -> Render a m (Texture a)
  DrawTexture :: (Texture a) -> Vec2 Int -> Render a m ()

type instance DispatchOf (Render t) = Dynamic

loadTexture
  :: Render a :> es
  => STB.Image
  -> Eff es (Texture a)
loadTexture = send . LoadTexture

drawTexture
  :: Render a :> es
  => Texture a
  -> Vec2 Int
  -> Eff es ()
drawTexture tex coord = send $ DrawTexture tex coord
