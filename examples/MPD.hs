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
import Foreign (Ptr, nullPtr)
import Foreign.C.ConstPtr (ConstPtr (..))
import System.Exit (exitFailure)

import Effectful ()

import Foreign.C.String (peekCString)
import Foreign.Lib.MPD qualified as F
import Foreign.TH

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
  uriStr <- peekCString $ unConstPtr uri
  putStrLn $ "Now playing: " <> uriStr
  F.mpdSongFree song

  F.mpdConnectionFree conn
  return ()

handleMPDErrors :: Ptr F.MPDConnection -> IO ()
handleMPDErrors conn = do
  err <- F.mpdConnectionGetError conn
  unless (err == F.mpdErrorSuccess) $ do
    msg <- F.mpdConnectionGetErrorMessage conn >>= peekCString . unConstPtr
    putStrLn $ "MPD failure: " <> msg
    exitFailure
