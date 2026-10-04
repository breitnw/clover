{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.Logger.Effect
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Logger.Effect (
  -- * Effect
  Log (..),

  -- * Operations
  logInfo,
  logWarn,
  logError,
) where

import Data.Text qualified as T
import Effectful
import Effectful.TH

data Log :: Effect where
  LogInfo :: T.Text -> Log m ()
  LogWarn :: T.Text -> Log m ()
  LogError :: T.Text -> Log m ()

makeEffect ''Log
