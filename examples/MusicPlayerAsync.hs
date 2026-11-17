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

import Data.Map qualified as M
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Fail

import Effectful.Logger
import Effectful.Logger.Handler.SDL
import Effectful.MusicPlayer.Async
import Effectful.MusicPlayer.Async.Handler.MPD
import Effectful.MusicPlayer.Sync.Handler.MPD qualified as SYNC
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL

import Util

windowSize :: Vec2 Int
-- windowSize = Vec2 196 196
-- windowSize = Vec2 300 300
windowSize = Vec2 200 200

windowRect :: Rect Float
windowRect = let Vec2 w h = windowSize in Rect 0 0 (fromIntegral w) (fromIntegral h)

albumArtProportionalRect :: Rect Float
albumArtProportionalRect = Rect 0.225 0.255 0.55 0.55

albumArtRect :: Rect Float
albumArtRect =
  let Vec2 sx sy = windowSize
      Rect x y w h = albumArtProportionalRect
   in Rect
        (x * fromIntegral sx)
        (y * fromIntegral sy)
        (w * fromIntegral sx)
        (h * fromIntegral sy)

main :: IO ()
main =
  -- TODO SYNC is terrible, want a Shared/Handler/MPD module
  let cfg =
        SYNC.MPDConfig
          { SYNC.mcHost = "localhost"
          , SYNC.mcPort = Just 6600
          , SYNC.mcPassword = Nothing
          , SYNC.mcTimeout = Just 100000
          }
      meta =
        SDLMeta
          { smName = "Music Player Demo (Async)"
          , smVersion = "v0.0.1"
          , smIdentifier = "com.breitnw.clover-renderer-demo"
          , smCreator = "Nick Breitling"
          , smCopyright = "(c) Nick Breitling 2026"
          , smUrl = "codeberg.org/breitnw/clover"
          , smType = "mediaplayer"
          }
      runApp =
        runConcurrent
          . runSDLRenderer windowSize "album art" meta
          . runMPDMusicPlayerAsync @SDL cfg
          . runFailIO
   in runEff $ runSDLLogger $ do
        runApp (appNote @SDL)

-- a static or dynamic thing that can be drawn at some position
data Drawable b m a
  = DStatic a
  | DDynTexture (m (Texture b))
  | DDynText (m (Text b))
  deriving (Functor, Foldable, Traversable)

-- a pair of a drawable and the position to draw it at
data Item b m a = Item (Drawable b m a) (Rect Float)
  deriving (Functor, Foldable, Traversable)

draw :: Render a :> es => Item a (Eff es) (Texture a) -> Eff es ()
draw (Item (DStatic tex) pos) = drawTexture tex pos
draw (Item (DDynTexture op) pos) = do
  currentTex <- op
  drawTexture currentTex pos
draw (Item (DDynText op) (Rect x y _ _)) = do
  currentText <- op
  drawText currentText (Vec2 x y)

-- themeFish
--   :: forall a es
--    . Render a :> es
--   => Texture a
--   -> T.Text
--   -> T.Text
--   -> T.Text
--   -> [Item]
-- themeFish albumart _title _artist _album =
--   ( Layout
--       [ (loadTextureBytes @a albumart, Rect 99 102 (143 - 99) (150 - 102))
--       ,
--         ( loadTextureFile $
--             Path "/home/breitnw/Desktop/clover/themes/fish/fishh.png"
--         , Rect 0 0 320 240
--         )
--       ]
--   , Layout []
--   )

-- themeNoa
--   :: forall a es
--    . Render a :> es
--   => Texture a
--   -> T.Text
--   -> T.Text
--   -> T.Text
--   -> (Layout (Eff es (Texture a)), Layout (Eff es (Text a)))
-- themeNoa albumart _title _artist _album =
--   ( Layout
--       [ (loadTextureBytes @a albumart, albumArtRect)
--       , -- ,
--         --   ( loadTextureFileEx
--         --       TextureOptions{tBlendMode = Just BModeMultiply}
--         --       (Path "data/noa/out/shadows.png")
--         --   , windowRect
--         --   )
--         (loadTextureFile $ Path "data/noa.png", windowRect)
--       ]
--   , Layout []
--   )

-- themeNote
--   :: forall a es
--    . Render a :> es
--   => [Item SDL (Eff es) (Eff es (Texture a))]
-- themeNote =
--   [ Item (DDynTexture currentArtwork) (Rect 30 31 (114 - 34) (118 - 31))
--   , Item (DStatic $ loadTextureFile $ Path "data/note/note-out.png") windowRect
--   , Item (DDynText )
--   , (loadText @a title textColor, Rect 114 51 0 0) -- HACK w and h ignored
--   , (loadText @a artist textColor, Rect 114 71 0 0)
--   , (loadText @a album textColor, Rect 124 91 0 0)
--   ]
--   where
--     textColor = Color 105 106 106 130

type TextureMap a = M.Map T.Text (Texture a)

appNote
  :: forall a es
   . (Log :> es, Render a :> es, PlayMusicAsync a :> es, Fail :> es)
  => Eff es ()
appNote =
  let staticTextures =
        M.fromList
          [ ("background", loadTextureFile @a $ Path "data/note/note-out.png")
          , ("progress", loadTextureFile @a $ Path "data/note/progress-out.png")
          ]
   in withTextures staticTextures $ do
        loopNote

loopNote
  :: forall a es
   . (Log :> es, Render a :> es, PlayMusicAsync a :> es)
  => TextureMap a
  -> Eff es ()
loopNote texMap = do
  status <- currentStatus @a
  song <- currentSong @a
  completion <- completionPercentage @a

  clear @a
  albumArt <- currentArtwork @a
  case albumArt of
    Nothing -> return ()
    Just aa -> drawTexture aa (Rect 30 31 (114 - 34) (118 - 31))
  drawTexture (texMap M.! "background") windowRect
  drawTexture
    (texMap M.! "progress")
    (Rect (fromInteger (truncate (lerp 40 160 completion))) 154 21 26)
  present @a
  waitFrame @a
  loopNote texMap

completionPercentage
  :: forall a es
   . PlayMusicAsync a :> es
  => Eff es Float
completionPercentage = do
  status <- currentStatus @a
  song <- currentSong @a
  return $ case song of
    Just (Song{sgDuration = Just dur}) -> psProgress status / dur
    _ -> 0

lerp :: Float -> Float -> Float -> Float
lerp a b p = a + (b - a) * p
