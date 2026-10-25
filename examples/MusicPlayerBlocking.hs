{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Main
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Main where

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent

import Effectful.Logger
import Effectful.Logger.Handler.SDL
import Effectful.MusicPlayer.Blocking
import Effectful.MusicPlayer.Blocking.Handler.MPD
import Util

main :: IO ()
main =
  let cfg =
        MPDConfig
          { mcHost = "/tmp/mpd_socket"
          , mcPort = Nothing
          , mcPassword = Nothing
          , mcTimeout = Nothing
          }
   in runEff
        . runSDLLogger
        . runMPDMusicPlayerBlocking cfg
        $ app

app :: (Log :> es, PlayMusic :> es) => Eff es ()
app = do
  song <- currentSong
  logInfo $ (T.pack . show) song
