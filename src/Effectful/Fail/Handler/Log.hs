{- |
Module      : Effectful.Fail.Handler.Log
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Implementation of the 'Effectful.Fail' effect that prints the message to a
logger before aborting computation.
-}
module Effectful.Fail.Handler.Log (
  runFailLog,
) where

import System.Exit (exitFailure)

import Data.Text qualified as T
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Fail

import Effectful.Logger

-- | Run an 'Effectful.Fail' computation, printing the message via
-- 'Effectful.Logger.Log' and aborting with 'exitFailure'.
runFailLog :: (IOE :> es, Log :> es) => Eff (Fail : es) a -> Eff es a
runFailLog = interpret_ $ \case
  Fail msg -> logError (T.pack msg) >> liftIO exitFailure
