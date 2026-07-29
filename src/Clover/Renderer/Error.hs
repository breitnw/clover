{- |
Module      : Renderer.Error
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Errors that may be raised by the render backend (generally fatal).
-}
module Clover.Renderer.Error where

data RendererError = TrackMissing | Unknown String
