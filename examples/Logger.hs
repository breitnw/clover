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

import Effectful.Logger
import Effectful.Logger.Handler.SDL

main :: IO ()
main = runEff $ runSDLLogger $ do
  -- Apparently we don't have to be in the SDL context to use the SDL logging
  -- functions! That's nice :)
  logInfo "An info message"
  logWarn "A warning message"
  logError "An error message"
