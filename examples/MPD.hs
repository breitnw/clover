{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module      : Main
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Main where

import Control.Monad (unless, when)
import Foreign (Ptr)
import System.Exit (exitFailure)

import Data.Text qualified as T
import Effectful ()

import Foreign.Lib.MPD qualified as F
import Foreign.TH
import Foreign.Util

main :: IO ()
main = do
  conn <- F.mpdConnectionNew $(ccstring "/tmp/mpd_socket") 0 0
  handleMPDErrors conn
  when (conn == nullPtr) $ do
    putStrLn "Out of memory"
    exitFailure

  song <- F.mpdRunCurrentSong conn
  handleMPDErrors conn
  when (song == nullPtr) $ do
    putStrLn "No song remaining"
    exitFailure

  uri <- F.mpdSongGetURI song
  uriText <- peekCString uri
  putStrLn . T.unpack $ "Now playing: " <> uriText
  F.mpdSongFree song

  F.mpdConnectionFree conn
  return ()

handleMPDErrors :: Ptr F.MPDConnection -> IO ()
handleMPDErrors conn = do
  err <- F.mpdConnectionGetError conn
  unless (err == F.MPD_ERROR_SUCCESS) $ do
    msg <- F.mpdConnectionGetErrorMessage conn >>= peekCString
    putStrLn . T.unpack $ "MPD failure: " <> msg
    exitFailure
