{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Clover.App
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Entry point and effect handler installation for the Clover app.
-}
module Clover.App (main) where

import Control.Monad ((>=>))

import Data.Text.IO qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Concurrent.Async
import Effectful.FileSystem

import Effectful.ImageLoader
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL
import Util

import Clover.Graphics.Thread

-- | Entry point for the application.
main :: IO ()
main = runEff $ do
  logger <- liftIO mkStdoutLogger
  L.runLog "clover" logger L.LogTrace runClover

-- | Create a logger to stdout.
mkStdoutLogger :: IO L.Logger
mkStdoutLogger = do
  L.mkLogger "stdout" $ \msg ->
    T.putStrLn $ L.showLogMessage Nothing msg

-- | Run the application in an effect, given the context shared between the two
-- threads (SDL, logging, failure)
runClover :: (L.Log :> es, IOE :> es) => Eff es ()
runClover = runConcurrent $ race_ runGraphicsThread runMusicThread
