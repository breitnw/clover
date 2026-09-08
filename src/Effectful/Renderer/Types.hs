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

data family Texture a

-- | A two-dimensional vector.
data Num a => Vec2 a = Vec2 a a
