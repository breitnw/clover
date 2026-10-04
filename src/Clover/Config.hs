{- |
Module      : Clover.CommandLine
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}

module Clover.CommandLine (parseCommandLineArgs) where

data CommandLineConfig = CommandLineConfig {
  clcGraphicsConfigPath :: Maybe FilePath,
  clcMusicConfigPath :: Maybe FilePath,
  clcAssetsPath :: Maybe FilePath,
    }

parseCommandLineArgs :: IOE :> es => Eff es
