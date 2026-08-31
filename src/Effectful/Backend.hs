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

  -- * Data
  module Effectful.Backend.Data,
) where

import Effectful.Backend.Data
import Effectful.Backend.Effect

-- TODO rename to Controller? or BackendController? or MusicBackend
