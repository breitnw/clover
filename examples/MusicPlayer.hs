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

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Error.Static
import TextShow qualified as T

import Effectful.Logger
import Effectful.Logger.Handler.SDL
import Effectful.MusicPlayer
import Effectful.MusicPlayer.Handler.MPD
import Effectful.Renderer
import Effectful.Renderer.Handler.SDL

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
          { smName = "Renderer Demo"
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
          . runSDLRenderer (Vec2 100 100) "album art" meta
   in runEff $ runSDLLogger $ do
        mpdResult <- runApp app
        case mpdResult of
          Left err -> logError (T.show err) -- do as I say, not as I do
          Right () -> return ()

app :: (Log :> es, PlayMusic :> es, Render SDL :> es) => Eff es ()
app = do
  maybeSong <- currentSong
  clear @SDL
  present @SDL
  case maybeSong of
    Nothing -> logInfo "No song playing"
    Just song -> do
      logInfo $ T.showt song
      maybeArt <- loadArtworkFull (sgID song)
      case maybeArt of
        Nothing -> logInfo "No art"
        Just art -> do
          withTexture @SDL (loadTextureBytes art) $ \artTex -> do
            drawTexture artTex (Rect 0 0 100 100)
          present @SDL
          waitForever
      return ()
  where
    waitForever = do
      waitFrame @SDL
      waitForever

loadArtworkFull :: (PlayMusic :> es => SongID -> Eff es (Maybe BS.ByteString))
loadArtworkFull songID = do
  art <- loadArtwork songID
  case art of
    Nothing -> return Nothing
    Just Waiting -> loadArtworkFull songID
    Just (Done artwork) -> return $ Just artwork
