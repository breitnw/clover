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

import Foreign.C (CInt (..), CString)

import Data.Text.Foreign qualified as T
import Effectful
import Effectful.Dispatch.Dynamic

import Effectful.Logger

foreign import ccall unsafe "SDL_LogInfo"
  c_sdlLogInfo :: CInt -> CString -> IO ()

foreign import ccall unsafe "SDL_LogWarn"
  c_sdlLogWarn :: CInt -> CString -> IO ()

foreign import ccall unsafe "SDL_LogError"
  c_sdlLogError :: CInt -> CString -> IO ()

runSDLLogger :: IOE :> es => Eff (Log : es) a -> Eff es a
runSDLLogger = interpret_ $ \case
  LogInfo msg -> liftIO $ T.withCString msg (c_sdlLogInfo 0)
  LogWarn msg -> liftIO $ T.withCString msg (c_sdlLogWarn 0)
  LogError msg -> liftIO $ T.withCString msg (c_sdlLogError 0)
