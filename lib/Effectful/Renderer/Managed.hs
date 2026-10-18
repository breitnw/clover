{-# LANGUAGE AllowAmbiguousTypes #-}

{- |
Module      : Effectful.Renderer.Managed
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Memory management helpers for the Renderer effect.
-}
module Effectful.Renderer.Managed (
  withTexture,
  withTextures,
) where

import Effectful
import Effectful.Exception
import Effectful.State.Static.Local

import Effectful.Renderer.Effect
import Effectful.Renderer.Types

-- | Run a computation with a texture (loaded from a file path) in scope.
withTexture
  :: forall a es b
   . Render a :> es
  => Eff es (Texture a)
  -- ^ Operation to load the texture
  -> (Texture a -> Eff es b)
  -- ^ Operation to run with the texture in scope
  -> Eff es b
withTexture doLoadTexture = bracket doLoadTexture (destroyTexture @a)

-- TODO ensure the proper behavior when one crashes

-- | Traverse any structure of items that can be loaded as textures (e.g.,
-- paths), and enter a context with an analogous structure full of textures.
withTextures
  :: forall a es b c t
   . (Traversable t, Render a :> es)
  => (b -> Eff es (Texture a))
  -- ^ Function to create a texture based on an item in the structure
  -> t b
  -- ^ Structure to map over
  -> (t (Texture a) -> Eff es c)
  -- ^ Operation to run with the textures in scope
  -> Eff es c
withTextures mkTexture items op =
  -- Unfortunately, this is not as simple as using bracket! if texture
  -- allocation fails, we want to also free all textures allocated thus far.
  -- So, the only choice is to stick them in a store as we allocate them, and
  -- free the whole store at the end.
  evalState [] $
    (traverse mkTexture' items >>= raise . op)
      `finally` cleanup
  where
    -- setup: create a texture and add it to the store
    mkTexture' :: b -> Eff (State [Texture a] : es) (Texture a)
    mkTexture' val = do
      tex <- raise $ mkTexture val
      modify (tex :)
      return tex
    -- cleanup: free all textures in the store
    cleanup :: Eff (State [Texture a] : es) ()
    cleanup = get @[Texture a] >>= mapM_ destroyTexture
