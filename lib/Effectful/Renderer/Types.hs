{- |
Module      : Effectful.Renderer.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Types (
  Texture,
  Text,
  Vec2 (..),
  Rect (..),
  Color (..),
  BlendMode (..),
  TextureOptions (..),
  defaultTextureOptions,
) where

import Data.Word (Word8)

-- | The texture type associated with a given rendering backend.
data family Texture a

-- | The text type associated with a given rendering backend
data family Text a

-- | A two-dimensional vector.
data Vec2 a = Vec2 a a
  deriving (Eq, Show)

-- | A rectangular area.
data Rect a = Rect a a a a
  deriving (Eq, Show)

data Color = Color Word8 Word8 Word8 Word8

data BlendMode = BModeMultiply | BModeAdd | BModeBlend

newtype TextureOptions = TextureOptions
  { tBlendMode :: Maybe BlendMode
  }

defaultTextureOptions :: TextureOptions
defaultTextureOptions = TextureOptions{tBlendMode = Nothing}
