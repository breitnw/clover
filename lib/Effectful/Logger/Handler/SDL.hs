{-# LANGUAGE MagicHash #-}

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

import GHC.Ptr qualified as GHC (Ptr (..)) -- needed for CString literal

import Data.Text.Foreign qualified as T
import Effectful
import Effectful.Dispatch.Dynamic

import Effectful.Foreign.SDL
import Effectful.Logger

-- TODO Make this only depend on SDL, not IOE ideally

runSDLLogger :: IOE :> es => Eff (Log : es) a -> Eff es a
runSDLLogger = interpret_ $ \case
  LogInfo msg -> liftIO $ T.withCString msg (c_sdlLogInfo 0 (GHC.Ptr "%s"#))
  LogWarn msg -> liftIO $ T.withCString msg (c_sdlLogWarn 0 (GHC.Ptr "%s"#))
  LogError msg -> liftIO $ T.withCString msg (c_sdlLogError 0 (GHC.Ptr "%s"#))
