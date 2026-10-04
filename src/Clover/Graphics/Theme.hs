{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Clover.Graphics.Theme
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Clover.Graphics.Theme (
  loadTheme,
) where

import Data.Text qualified as T
import Effectful
import Effectful.FileSystem
import Effectful.FileSystem.IO.ByteString.Lazy qualified as FS
import Effectful.Log qualified as L

import Util

import Clover.Graphics.Types

loadTheme
  :: (L.Log :> es, FileSystem :> es)
  => FilePath
  -> Eff es (Result (Config FilePath))
loadTheme themePath = do
  let configPathText = T.pack configPath -- for logging
  L.logTrace_ $ "Trying to read theme from file " <> configPathText
  configFileExists <- doesFileExist configPath
  if configFileExists
    then do
      contents <- FS.readFile configPath
      L.logTrace_ "Decoding config"
      case A.decode contents of
        Nothing -> return $ Left "Failed to decode config from JSON"
        Just decoded -> return $ Right decoded
    else return $ Left $ "File " <> configPathText <> " does not exist"
