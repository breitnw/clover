{-# LANGUAGE AllowAmbiguousTypes #-}
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
import Effectful.Error.Static
import TextShow qualified as T

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
   in runEff $ runSDLLogger $ do
        mpdResult <-
          runErrorNoCallStack @(Annotated MPDServerError) $
            runMPDMusicPlayerBlocking cfg app

        case mpdResult of
          Left err -> logError (T.show err) -- do as I say, not as I do
          Right () -> return ()

app :: (Log :> es, PlayMusic :> es) => Eff es ()
app = do
  maybeSong <- currentSong
  case maybeSong of
    Nothing -> logInfo "No song playing"
    Just song -> do
      logInfo $ T.showt song
      art <- loadArtwork (sgID song)
      return ()
