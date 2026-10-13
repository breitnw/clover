{-# LANGUAGE TemplateHaskellQuotes #-}

{- |
Module      : Foreign.TH
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

TemplateHaskell utilities for working with foreign libraries.
-}
module Foreign.TH (
  ccstring,
) where

import Foreign.C.ConstPtr (ConstPtr (..))
import GHC.Base (ord)
import GHC.Ptr qualified as GHC
import Language.Haskell.TH

-- | Utility for creating a statically allocated ConstCString.
ccstring :: String -> Q Exp
ccstring s = do
  let toWord = fromIntegral . ord
  let bytes = map toWord s
  return $ AppE (ConE 'ConstPtr) (AppE (ConE 'GHC.Ptr) (LitE (StringPrimL bytes)))
