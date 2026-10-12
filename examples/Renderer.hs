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

import Effectful
import Effectful.Concurrent

import Effectful.Logger.Handler.SDL
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL

main :: IO ()
main =
  let meta =
        SDLMeta
          { smName = "Renderer Demo"
          , smVersion = "v0.0.1"
          , smIdentifier = "com.breitnw.clover-renderer-demo"
          , smCreator = "Nick Breitling"
          , smCopyright = "(c) Nick Breitling 2026"
          , smUrl = "codeberg.org/breitnw/clover"
          , smType = "mediaplayer"
          }
   in runEff
        . runSDLLogger
        . runConcurrent
        . runSDLRenderer (Vec2 100 100) "renderer demo" meta
        $ app @SDL

app
  :: forall a es
   . Render a :> es
  => Eff es ()
app = do
  tex <- loadTexture @a "data/image3.jpg"
  loop tex (Rect 0 0 30 30)

loop
  :: forall a es
   . Render a :> es
  => Texture a
  -> Rect Float
  -> Eff es ()
loop tex rect@(Rect x y w h) = do
  drawTexture @a tex rect
  present @a
  waitFrame @a
  loop tex (Rect x y (w + 1) h)
