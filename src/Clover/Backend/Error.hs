-- | Module    : Backend.Error
-- Copyright   : (c) Nick Breitling 2026
-- License     : GPL v3 (see LICENSE)
-- Maintainer  : Nick Breitling <breitling.nw@gmail.com>
-- Stability   : alpha
--
-- Errors that may be raised by the music backend.
module Clover.Backend.Error where

class IntoBackendError e where
  intoBackendError :: e -> BackendError

data BackendError = TrackMissing | Unknown String
