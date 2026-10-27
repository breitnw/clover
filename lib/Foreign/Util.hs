{- |
Module      : Foreign.Util
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Utility functions for working with foreign libraries.
-}
module Foreign.Util (
  ConstCString,
  IsPtr (..),
) where

import Foreign qualified as P (Ptr, nullPtr)
import Foreign.C (CChar)
import Foreign.C.ConstPtr (ConstPtr (..))

import Data.Text qualified as T
import Data.Text.Foreign qualified as T

-- | The 'const char*' type in C.
type ConstCString = ConstPtr CChar

class IsPtr p where
  withCString :: T.Text -> (p CChar -> IO a) -> IO a
  peekCString :: p CChar -> IO T.Text
  nullPtr :: p a

  -- | Convert a pointer that can be NULL to a Maybe, which is Nothing if the
  -- pointer was NULL and Just (Ptr x) otherwise
  --
  -- STYLE: don't use this for error handling; just check if the pointer is
  -- nullPtr directly. Instead, use it for instances where Nothing is a valid
  -- option; e.g., no current song exists.
  nullToNothing :: Eq (p a) => p a -> Maybe (p a)
  nullToNothing ptr | ptr == nullPtr = Nothing
  nullToNothing ptr = Just ptr

instance IsPtr P.Ptr where
  withCString = T.withCString
  peekCString = T.peekCString
  nullPtr = P.nullPtr

instance IsPtr ConstPtr where
  withCString t op = T.withCString t $ op . ConstPtr
  peekCString = T.peekCString . unConstPtr
  nullPtr = ConstPtr P.nullPtr
