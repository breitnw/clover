{- |
Module      : Effectful.ImageLoader
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.ImageLoader (
  -- * Effect
  LoadImages,

  -- ** Handlers
  runLoadImages,

  -- * Operations
  loadImagePath,
  loadImageBytes,
) where

import Data.ByteString

import qualified Codec.Image.STB as STB
import Effectful
import Effectful.Dispatch.Static

-- Reference: Effectful.Console.Effect
data LoadImages :: Effect

type instance DispatchOf LoadImages = Static WithSideEffects
data instance StaticRep LoadImages = Console

-- | Run the 'LoadImages' effect
runLoadImages
  :: (HasCallStack, IOE :> es) => Eff (LoadImages : es) a -> Eff es a
runLoadImages = evalStaticRep Console

-- TODO should these be in another module?
-- Effectful.Console.Effect places them in another module, but that also has
-- multiple different interpretations (lazy and strict), I think
-- Maybe something like Effectful.Image.STB holds the operations (and exports
-- the effect handler), then we have Effectful.Image.Effect which holds the
-- effect and the handler

-- | Lifted 'STB.loadImage'
loadImagePath
  :: LoadImages :> es
  => FilePath
  -> Eff es (Either String STB.Image)
loadImagePath = unsafeEff_ . STB.loadImage

-- | Lifted 'STB.decodeImage'
loadImageBytes
  :: LoadImages :> es
  => ByteString
  -> Eff es (Either String STB.Image)
loadImageBytes = unsafeEff_ . STB.decodeImage
