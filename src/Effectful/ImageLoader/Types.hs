{-# LANGUAGE DeriveGeneric #-}

{- |
Module      : Effectful.ImageLoader.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.ImageLoader.Types (
  Image (..),
  ImageMeta (..),
) where

import GHC.Generics

import Codec.Image.STB qualified as STB
import Data.Aeson qualified as A
import Data.Text qualified as T

-- | Metadata concerning an image.
newtype ImageMeta = ImageMeta {imMetaName :: T.Text}
  deriving (Generic)

instance A.ToJSON ImageMeta

-- | A raw image loaded in memory, with some associated metadata.
data Image = Image {imMeta :: ImageMeta, imData :: STB.Image}
