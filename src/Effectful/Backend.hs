{- |
Module      : Effectful.Backend
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Backend (
  -- * Effect
  module Effectful.Backend.Effect,

  -- * Types
  module Effectful.Backend.Types,
) where

import Effectful.Backend.Effect
import Effectful.Backend.Types

-- TODO rename to Controller? or BackendController? or MusicBackend
