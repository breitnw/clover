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
  cstring,
) where

import GHC.Base (ord)
import GHC.Ptr qualified as GHC
import Language.Haskell.TH

-- | Utility for creating a statically allocated CString.
cstring :: String -> Q Exp
cstring s = do
  let toWord = fromIntegral . ord
  let bytes = map toWord s
  return $ AppE (ConE 'GHC.Ptr) (LitE (StringPrimL bytes))
