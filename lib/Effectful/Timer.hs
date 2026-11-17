{- |
Module      : Effectful.Timer
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Timer (
  Time,
  runTimer,
  getPOSIXTime,
  module Data.Time.Clock.POSIX,
) where

-- NOTE timer isn't the best name...

import Data.Time.Clock.POSIX hiding (getPOSIXTime)
import Data.Time.Clock.POSIX qualified as C (getPOSIXTime)
import Effectful
import Effectful.Dispatch.Static

data Time :: Effect
type instance DispatchOf Time = Static WithSideEffects
data instance StaticRep Time = Time

runTimer :: IOE :> es => Eff (Time : es) a -> Eff es a
runTimer = evalStaticRep Time

getPOSIXTime :: Time :> es => Eff es POSIXTime
getPOSIXTime = unsafeEff_ C.getPOSIXTime
