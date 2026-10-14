{- |
Module      : Foreign.Util
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Utility functions for working with foreign libraries.
-}
module Foreign.Util where

import Foreign.C (CChar)
import Foreign.C.ConstPtr (ConstPtr (..))

import Data.Text qualified as T
import Data.Text.Foreign qualified as T

-- | The 'const char*' type in C.
type ConstCString = ConstPtr CChar

-- | Like `Data.Text.Foreign.withCString`, but gives a `ConstCString`.
withConstCString :: T.Text -> (ConstPtr CChar -> IO a) -> IO a
withConstCString t op = T.withCString t $ op . ConstPtr
