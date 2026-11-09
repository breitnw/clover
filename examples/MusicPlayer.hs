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

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Error.Static
import Effectful.Fail
import TextShow qualified as T

import Effectful.Logger
import Effectful.Logger.Handler.SDL
import Effectful.MusicPlayer
import Effectful.MusicPlayer.Handler.MPD
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL

import Util

windowSize :: Vec2 Int
-- windowSize = Vec2 196 196
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
  let cfg =
        MPDConfig
          { mcHost = "localhost"
          , mcPort = Just 6600
          , mcPassword = Nothing
          , mcTimeout = Just 100000
          }
      meta =
        SDLMeta
          { smName = "Music Player Demo"
          , smVersion = "v0.0.1"
          , smIdentifier = "com.breitnw.clover-renderer-demo"
          , smCreator = "Nick Breitling"
          , smCopyright = "(c) Nick Breitling 2026"
          , smUrl = "codeberg.org/breitnw/clover"
          , smType = "mediaplayer"
          }
      runApp =
        runErrorNoCallStack @(Annotated MPDServerError)
          . runMPDMusicPlayer cfg
          . runConcurrent
          . runSDLRenderer windowSize "album art" meta
          . runFailIO
   in runEff $ runSDLLogger $ do
        mpdResult <- runApp (app @SDL)
        case mpdResult of
          Left err -> logError (T.show err) -- do as I say, not as I do
          Right () -> return ()

-- A layout is a list of texture-like things and their corresponding rects
newtype Layout a = Layout [(a, Rect Float)]
  deriving (Functor, Foldable, Traversable)

themeNoa
  :: forall a es
   . Render a :> es
  => BS.ByteString -> Layout (Eff es (Texture a))
themeNoa albumart =
  Layout
    [ (loadTextureBytes @a albumart, albumArtRect)
    , -- ,
      --   ( loadTextureFileEx
      --       TextureOptions{tBlendMode = Just BModeMultiply}
      --       (Path "data/noa/out/shadows.png")
      --   , windowRect
      --   )
      (loadTextureFile $ Path "data/noa/out/foreground.png", windowRect)
    ]

themeNote
  :: forall a es
   . Render a :> es
  => BS.ByteString
  -> T.Text
  -> T.Text
  -> T.Text
  -> (Layout (Eff es (Texture a)), Layout (Eff es (Text a)))
themeNote albumart title artist album =
  ( Layout
      [ (loadTextureBytes @a albumart, Rect 30 31 (114 - 34) (118 - 31))
      , (loadTextureFile $ Path "data/note/note-out.png", windowRect)
      , (loadTextureFile $ Path "data/note/progress-out.png", Rect 37 154 21 26)
      ]
  , Layout
      [ (loadText @a title textColor, Rect 114 51 0 0) -- HACK w and h ignored
      , (loadText @a artist textColor, Rect 114 71 0 0)
      , (loadText @a album textColor, Rect 124 91 0 0)
      ]
  )
  where
    textColor = Color 105 106 106 130

app
  :: forall a es
   . (Log :> es, PlayMusic :> es, Render a :> es, Fail :> es)
  => Eff es ()
app = do
  clear @a
  present @a
  Just song <- currentSong

  let title = maybe "No album" id (sgTitle song)
      artist = maybe "No artist" id (sgArtist song)
      album = maybe "No album" id (sgAlbum song)

  Just albumart <- loadArtworkFull (sgID song)
  let (textures, texts) = themeNote @a albumart title artist album
  withTexts texts $ \rtexts ->
    withTextures textures $ \rtextures ->
      loop (rtextures, rtexts)

loop
  :: forall a es
   . (Log :> es, Render a :> es)
  => (Layout (Texture a), Layout (Text a))
  -> Eff es ()
loop l@((Layout textures), (Layout texts)) = do
  clear @a
  mapM_ (uncurry (drawTexture @a)) textures
  mapM_ (\(rtxt, Rect x y _ _) -> drawText @a rtxt (Vec2 x y)) texts -- ugly :(
  present @a
  waitFrame @a
  loop l

loadArtworkFull :: (PlayMusic :> es => SongID -> Eff es (Maybe BS.ByteString))
loadArtworkFull songID = do
  art <- loadArtwork songID
  case art of
    Nothing -> return Nothing
    Just Waiting -> loadArtworkFull songID
    Just (Done artwork) -> return $ Just artwork
