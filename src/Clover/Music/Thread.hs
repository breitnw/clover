{- |
Module      : Clover.Music.Thread
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Clover.Music.Thread (runMusicThread) where

import Effectful
import Effectful.Concurrent

import Effectful.Logger
import Effectful.MusicPlayer

-- | Run the music thread from the app context.
runMusicThread
  :: (Log :> es, Concurrent :> es, IOE :> es)
  => Eff es ()
runMusicThread = _

-- | The music thread, given the required context.
musicThread
  :: (PlayMusic :> es, Concurrent :> es)
  => Eff es ()
musicThread = _
