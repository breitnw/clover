{-# LANGUAGE DeriveGeneric #-}

{- |
Module      : Effectful.Renderer.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Types (
  Texture,
  Vec2 (..),
) where

import GHC.Generics (Generic)

-- | The texture type associated with a given rendering backend.
data family Texture a

-- | A two-dimensional vector.
data Vec2 a = Vec2 a a
  deriving (Eq, Show, Generic)
