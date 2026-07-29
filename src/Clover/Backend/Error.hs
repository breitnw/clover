{- |
Module      : Clover.Backend.Error
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Errors that may be raised by the music backend (generally non-fatal).
-}
module Clover.Backend.Error where

import Control.Exception as E

data BackendError
  = -- | Track does not exist with requested identifier
    FileMissing
  | -- | Music backend is not available
    NoBackend
  | -- | Failed to establish a connection to the music backend
    ConnectionError
  | -- | Unexpected error within the backend, fatal
    Unexpected String
