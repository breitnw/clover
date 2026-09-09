{- |
Module      : Effectful.Renderer.Managed
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Derived actions for 'Effectful.Renderer' providing automatic memory management.
-}
module Effectful.Renderer.Managed (
  withTexture,
) where

import Effectful
import Effectful.Exception

import Effectful.ImageLoader.Types
import Effectful.Renderer.Effect
import Effectful.Renderer.Types

-- | Run a command with a texture in scope, loaded from an image.
--
-- Prefer 'withTexture' over 'loadTexture' and 'unloadTexture' when possible.
withTexture
  :: Render a :> es
  => Image
  -> (Texture a -> Eff es b)
  -> Eff es b
withTexture im = bracket (loadTexture im) destroyTexture
