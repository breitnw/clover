{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Util
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Utilities for common patterns.
-}
module Util (
  orElseDo,
  rightToMaybe,
  logWarn,
  logWarn_,
  logErr,
  logErr_,
) where

import Data.Aeson qualified as A
import Data.Text qualified as T
import Effectful
import Effectful.Log qualified as L

-- | Run the first computation. If it fails, return the result of the second computation.
orElseDo :: Monad m => m (Maybe a) -> m (Maybe a) -> m (Maybe a)
orElseDo x y = x >>= maybe y (return . return)

-- | Convert the right of an Either into a Maybe
rightToMaybe :: Either a b -> Maybe b
rightToMaybe (Right x) = Just x
rightToMaybe _ = Nothing

-- TODO might be better to put these in a dedicated logging module.

warnPrefix :: T.Text
warnPrefix = "[WARNING] "

errPrefix :: T.Text
errPrefix = "[ERROR] "

-- | Log a message as a warning with some data
logWarn :: (L.Log :> es, A.ToJSON a) => T.Text -> a -> Eff es ()
logWarn msg = L.logAttention (T.append warnPrefix msg)

-- | Log a message as a warning
logWarn_ :: L.Log :> es => T.Text -> Eff es ()
logWarn_ msg = L.logAttention_ (T.append warnPrefix msg)

-- | Log a message as an error with some data
logErr :: (L.Log :> es, A.ToJSON a) => T.Text -> a -> Eff es ()
logErr msg = L.logAttention (T.append errPrefix msg)

-- | Log a message as an error
logErr_ :: L.Log :> es => T.Text -> Eff es ()
logErr_ msg = L.logAttention_ (T.append errPrefix msg)
