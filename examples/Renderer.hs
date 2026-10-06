{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Main
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Main where

import Effectful
import Effectful.Concurrent

import Effectful.ImageLoader
import Effectful.Logger
import Effectful.Logger.Handler.SDL
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL

main :: IO ()
main = runEff
  . runSDLLogger
  . runConcurrent
  . runLoadImages
  . runSDLRenderer (Vec2 100 100) "renderer demo"
  $ do
    return ()
