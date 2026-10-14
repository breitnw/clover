{- |
Module      : Effectful.Renderer.Managed
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Memory management helpers for the Renderer effect.
-}
module Effectful.Renderer.Managed where

import Data.Text qualified as T
import Effectful
import Effectful.Exception

import Effectful.Renderer.Effect
import Effectful.Renderer.Types
import Util

-- TODO would be nice to have some sort of Path datatype

-- | Run a computation with a texture (loaded from a file path) in scope.
withTexture
  :: Render a :> es
  => Path
  -- ^ Path of the image to load
  -> (Texture a -> Eff es b)
  -- ^ Operation to run with the texture in scope
  -> Eff es b
withTexture filePath = bracket (loadTexture filePath) destroyTexture
