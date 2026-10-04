{- |
Module      : Main
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Trivial wrapper module around "Clover.App"
-}
module Main where

import Clover.App qualified

main :: IO ()
main = Clover.App.main
