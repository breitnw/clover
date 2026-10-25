{- |
Module      : Foreign.Util
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Utility functions for working with foreign libraries.
-}
module Foreign.Util where

import Foreign (Ptr, nullPtr)
import Foreign.C (CChar)
import Foreign.C.ConstPtr (ConstPtr (..))

import Data.Text qualified as T
import Data.Text.Foreign qualified as T

-- | The 'const char*' type in C.
type ConstCString = ConstPtr CChar

constNullPtr :: ConstPtr a
constNullPtr = ConstPtr nullPtr

-- | Like `Data.Text.Foreign.withCString`, but gives a `ConstCString`.
withConstCString :: T.Text -> (ConstCString -> IO a) -> IO a
withConstCString t op = T.withCString t $ op . ConstPtr

-- | Like `Data.Text.Foreign.peekCString`, but takes a `ConstCString`
peekConstCString :: ConstCString -> IO T.Text
peekConstCString = T.peekCString . unConstPtr

-- | Convert a pointer that can be NULL to a Maybe, which is Nothing if the
-- pointer was NULL and Just (Ptr x) otherwise
-- nullToNothing :: Ptr a -> Maybe (Ptr a)
-- nullToNothing ptr = if ptr == nullPtr then Nothing else Just ptr
