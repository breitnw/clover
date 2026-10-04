{- |
Module      : Util
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Utilities for common patterns.
-}
module Util (
  Result,
  unwrap,
  orElseDo,
  rightToMaybe,
) where

import Data.Text qualified as T
import Effectful
import Effectful.Fail

-- | Helper type similar to Anyhow's Result
type Result = Either T.Text

-- | Unwrap a 'Result', printing a message and exiting immediately if it is a
-- failure value
unwrap :: Fail :> es => Result a -> Eff es a
unwrap v = case v of
  Right success -> return success
  Left msg -> fail (T.unpack msg) -- XXX unpack here is a bit disgusting, but failing an unwrap should hopefully be pretty rare...

-- | Run the first computation. If it fails, return the result of the second computation.
orElseDo :: Monad m => m (Maybe a) -> m (Maybe a) -> m (Maybe a)
orElseDo x y = x >>= maybe y (return . return)

-- | Convert the right of an Either into a Maybe
rightToMaybe :: Either a b -> Maybe b
rightToMaybe (Right x) = Just x
rightToMaybe _ = Nothing
