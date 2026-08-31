{- |
Module      : Util
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Utilities for common patterns.
-}
module Util where

-- | Run the first computation. If it fails, return the result of the second computation.
orElseDo :: Monad m => m (Maybe a) -> m (Maybe a) -> m (Maybe a)
orElseDo x y = x >>= maybe y (return . return)
