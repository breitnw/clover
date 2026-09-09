{- |
Module      : Effectful.ImageLoader.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.ImageLoader.Effect (
  -- * Effect
  LoadImages,

  -- ** Handlers
  runLoadImages,

  -- * Operations
  loadImagePath,
  loadImageBytes,
) where

import Data.ByteString

import Codec.Image.STB qualified as STB
import Data.Text qualified as T
import Effectful
import Effectful.Dispatch.Static

import Effectful.ImageLoader.Types

-- Reference: Effectful.Console.Effect
data LoadImages :: Effect

type instance DispatchOf LoadImages = Static WithSideEffects
data instance StaticRep LoadImages = Console

-- | Run the 'LoadImages' effect
runLoadImages
  :: (HasCallStack, IOE :> es) => Eff (LoadImages : es) a -> Eff es a
runLoadImages = evalStaticRep Console

-- TODO use Text here instead of FilePath (which is a String)?

-- | Load an 'Image' from a file path.
loadImagePath
  :: LoadImages :> es
  => FilePath
  -> Eff es (Either T.Text Image)
loadImagePath path = do
  unsafeEff_ $
    STB.loadImage path >>= \case
      Left err -> return $ Left (T.pack err)
      Right im -> return . Right $ Image (ImageMeta (T.pack path)) im

-- | Load an 'Image' from a 'ByteString'.
loadImageBytes
  :: LoadImages :> es
  => T.Text
  -- ^ The name to assign the image
  -> ByteString
  -- ^ The image data
  -> Eff es (Either T.Text Image)
loadImageBytes name bytes = do
  unsafeEff_ $
    STB.decodeImage bytes >>= \case
      Left err -> return $ Left (T.pack err)
      Right im -> return . Right $ Image (ImageMeta name) im
