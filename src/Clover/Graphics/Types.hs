{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE FlexibleInstances #-}

-- TODO rename to DOM?

{- |
Module      : Clover.Graphics.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Types used by graphics thread.
-}
module Clover.Graphics.Types (
  Config (..),
  Widget (..),
  Element (..),
) where

import Effectful.Renderer

-- | The UI configuration, specifying all elements to be drawn.
data Config a = Config
  { cfgBackground :: a
  , cfgElements :: [Element a]
  }
  deriving (Functor, Foldable, Traversable)

-- | A UI element is a widget with a position
data Element a = Element
  { elPosn :: Vec2 Int
  , elWidget :: Widget a
  }
  deriving (Functor, Foldable, Traversable)

-- | A UI widget is a something that can be drawn to the screen
data Widget a
  = WTexture a
  | WButton a
  | WAlbumArt
  deriving (Functor, Foldable, Traversable)
