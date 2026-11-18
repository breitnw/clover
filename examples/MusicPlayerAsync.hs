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

import Control.Monad (forM_)
import Data.Maybe (fromMaybe)
import System.Environment (getArgs)

import Data.Map qualified as M
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Fail

import Effectful.Logger.Handler.SDL
import Effectful.MusicPlayer.Async
import Effectful.MusicPlayer.Async.Handler.MPD
import Effectful.MusicPlayer.Sync.Handler.MPD qualified as SYNC
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL
import Effectful.Timer

import Util

-- APP INIT ====================================================================

main :: IO ()
main = do
  [theme] <- getArgs
  let (app, windowSize) = themes @SDL M.! T.pack theme -- ick
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
      -- app effect stack
      runApp =
        runSDLLogger
          . runConcurrent
          . runSDLRenderer windowSize "album art" meta
          . runTimer
          . runMPDMusicPlayerAsync @SDL cfg
          . runFailIO
  runEff $ runApp app

-- THEME UTILS =================================================================

-- XXX creating a new Text every frame is bad for performance, but ok for short
-- term stuff and demonstration
drawTextOnce
  :: forall a es
   . Render a :> es
  => T.Text -> Color -> Vec2 Float -> Eff es ()
drawTextOnce t color posn = withText @a (loadText t color) $ \renText ->
  drawText renText posn

cycleWindow :: T.Text -> T.Text -> Int -> Int -> T.Text
cycleWindow text _ windowLen _ | T.length text <= windowLen = text
cycleWindow text sep windowLen offset =
  let textWithSep = text <> sep
      splitIdx = mod offset (T.length textWithSep)
      (start, end) = T.splitAt splitIdx textWithSep
   in T.take windowLen (end <> start)

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

-- | Linear interpolation between two values.
lerp :: Fractional a => a -> a -> a -> a
lerp a b p = a + (b - a) * p

-- THEMES ======================================================================

themes
  :: forall a es
   . (Render a :> es, PlayMusicAsync a :> es)
  => M.Map T.Text (Eff es (), Vec2 Int)
themes =
  M.fromList
    [ ("fish", (themeFish @a, Vec2 320 240))
    , ("felt", (themeFelt @a, Vec2 257 237))
    , ("note", (themeNote @a, Vec2 200 200))
    ]

-- NOA theme -------------------------------------------------------------------

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

-- fish theme ------------------------------------------------------------------

themeFish
  :: forall a es
   . (Render a :> es, PlayMusicAsync a :> es)
  => Eff es ()
themeFish =
  let staticTextures =
        M.fromList @T.Text
          [ ("frame", loadTextureFile @a $ Path "data/fish/render-wood.png")
          , ("frame-hover", loadTextureFile @a $ Path "data/fish/render-wood-in.png")
          , ("text-background", loadTextureFile @a $ Path "data/fish/text-background.png")
          ]
   in withTextures staticTextures loop
  where
    loop texMap = do
      maybeSong <- currentSong @a
      status <- currentStatus @a

      clear @a
      let fishRect = Rect (-15) 0 320 240
      drawTexture (texMap M.! "text-background") fishRect
      albumArt <- currentArtwork @a
      case albumArt of
        Nothing -> return ()
        Just aa -> drawTexture aa (Rect 80 100 50 50)
      forM_ maybeSong $ \s -> do
        let title = fromMaybe "no title" (sgTitle s)
            artist = fromMaybe "no artist" (sgArtist s)
            album = maybe "" (" - " <>) (sgAlbum s)
            cycleOffset = truncate (psProgress status * 1.2)
        drawTextOnce @a
          (cycleWindow (artist <> " - " <> title <> album) "   " 14 cycleOffset)
          (Color 220 255 255 255)
          (Vec2 130 135)
      drawTexture (texMap M.! "frame") fishRect
      present @a
      waitFrame @a
      loop texMap

-- note theme ------------------------------------------------------------------

themeNote
  :: forall a es
   . (Render a :> es, PlayMusicAsync a :> es)
  => Eff es ()
themeNote =
  let staticTextures =
        M.fromList @T.Text
          [ ("background", loadTextureFile @a $ Path "data/note/note-out.png")
          , ("progress", loadTextureFile @a $ Path "data/note/progress-out.png")
          ]
   in withTextures staticTextures loop
  where
    loop texMap = do
      status <- currentStatus @a
      maybeSong <- currentSong @a
      completion <- completionPercentage @a

      clear @a
      albumArt <- currentArtwork @a
      case albumArt of
        Nothing -> return ()
        Just aa -> drawTexture aa (Rect 30 31 (114 - 34) (118 - 31))
      drawTexture (texMap M.! "background") (Rect 0 0 200 200)
      forM_ maybeSong $ \s -> do
        let title = fromMaybe "no title" (sgTitle s)
            artist = fromMaybe "no artist" (sgArtist s)
            album = fromMaybe "no album" (sgAlbum s)
            cycleOffset = truncate (psProgress status * 1.2)
            textColor = Color 105 106 106 130
        drawTextOnce @a
          (cycleWindow title "   " 12 cycleOffset)
          textColor
          (Vec2 114 51)
        drawTextOnce @a
          (cycleWindow artist "   " 12 cycleOffset)
          textColor
          (Vec2 114 71)
        drawTextOnce @a
          (cycleWindow album "   " 11 cycleOffset)
          textColor
          (Vec2 124 91)
        return ()
      drawTexture
        (texMap M.! "progress")
        (Rect (fromInteger (truncate (lerp 40 160 completion))) 154 21 26)
      present @a
      waitFrame @a
      loop texMap

-- felt theme ------------------------------------------------------------------

themeFelt
  :: forall a es
   . (Render a :> es, PlayMusicAsync a :> es)
  => Eff es ()
themeFelt =
  let staticTextures =
        M.fromList @T.Text
          [ ("frame", loadTextureFile @a $ Path "data/felt/out-new.png")
          , ("progress", loadTextureFile @a $ Path "data/felt/button-out.png")
          ]
   in withTextures staticTextures loop
  where
    loop texMap = do
      status <- currentStatus @a
      maybeSong <- currentSong @a
      completion <- completionPercentage @a

      clear @a
      albumArt <- currentArtwork @a
      case albumArt of
        Nothing -> return ()
        Just aa -> drawTexture aa (Rect 50 20 160 160)
      drawTexture (texMap M.! "frame") (Rect 0 0 257 237)
      forM_ maybeSong $ \s -> do
        let title = fromMaybe "no title" (sgTitle s)
            artist = fromMaybe "no artist" (sgArtist s)
            album = maybe "" (" - " <>) (sgAlbum s) -- lolz
            cycleOffset = truncate (psProgress status * 1.2)
        drawTextOnce @a
          (cycleWindow title "   " 14 cycleOffset)
          (Color 10 20 20 255)
          (Vec2 20 170)
        drawTextOnce @a
          (cycleWindow (artist <> album) "   " 14 cycleOffset)
          (Color 10 20 20 255)
          (Vec2 20 183)
        return ()
      drawTexture
        (texMap M.! "progress")
        (Rect (fromInteger (truncate (lerp 10 80 completion))) 192 30 30)
      present @a
      waitFrame @a
      loop texMap
