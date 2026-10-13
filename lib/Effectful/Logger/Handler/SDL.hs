{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Effectful.Logger.Handler.SDL
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Logger.Handler.SDL (
  runSDLLogger,
) where

import Effectful
import Effectful.Dispatch.Dynamic

import Effectful.Logger
import Foreign.SDL qualified as F
import Foreign.TH
import Foreign.Util

-- TODO Make this only depend on SDL, not IOE ideally

runSDLLogger :: IOE :> es => Eff (Log : es) a -> Eff es a
runSDLLogger = interpret_ $ \case
  LogInfo msg -> liftIO $ withConstCString msg (F.sdlLogInfo 0 $(ccstring "%s"))
  LogWarn msg -> liftIO $ withConstCString msg (F.sdlLogWarn 0 $(ccstring "%s"))
  LogError msg -> liftIO $ withConstCString msg (F.sdlLogError 0 $(ccstring "%s"))
