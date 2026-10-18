{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DeriveTraversable #-}
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
import Util

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

-- A layout is a list of texture-like things and their corresponding rects
newtype Layout a = Layout [(a, Rect Float)]
  deriving (Functor, Foldable, Traversable)

app
  :: forall a es
   . Render a :> es
  => Eff es ()
app = do
  let layout =
        Layout
          [ (Path "data/image1.jpg", Rect 0 0 20 20)
          , (Path "data/image2.jpg", Rect 30 0 20 20)
          , (Path "data/image3.jpg", Rect 0 30 30 20)
          ]
  -- withTextures is so sexy
  withTextures @a loadTexture layout loop

loop
  :: forall a es
   . Render a :> es
  => Layout (Texture a)
  -> Eff es ()
loop layout@(Layout l) = do
  mapM_ (uncurry (drawTexture @a)) l
  present @a
  waitFrame @a
  loop layout
