{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effectful.Renderer.Handler.SDL
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Handler.SDL (
  SDL,
  SDLMeta (..),
  runSDLRenderer,
) where

import Control.Monad (forM_, unless)
import Foreign (
  Bits ((.|.)),
  ForeignPtr,
  Ptr,
  newForeignPtr,
  nullPtr,
  toBool,
  withForeignPtr,
 )
import Foreign.C (CFloat (..), withCString)
import Foreign.Marshal (with)

import Data.Text qualified as T
import Data.Text.Foreign qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Dispatch.Dynamic
import Effectful.Exception
import Effectful.Reader.Static

import Effectful.Logger
import Effectful.Renderer.Effect
import Effectful.Renderer.Types
import Foreign.SDL qualified as F
import Foreign.SDLImage qualified as F

-- TODO it would be nice to use ForeignPtr in this module to take advantage of
-- GC for textures, surfaces, etc
-- Monad can still handle freeing window/renderer

-- EFFECT HANDLER --------------------------------------------------------------

-- | An empty type representing the SDL render backend.
data SDL

-- | A SDL texture comes with a name and data
-- NOTE designated metadata type
data instance Texture SDL = Texture T.Text (ForeignPtr F.SDLTexture)

-- | The resources available when inside a SDL window context.
data SDLContext = SDLContext
  { scWindow :: Ptr F.SDLWindow
  , scRenderer :: Ptr F.SDLRenderer
  }

-- TODO use template-haskell to extract this info from clover.cabal
data SDLMeta = SDLMeta
  { smName :: T.Text
  , smVersion :: T.Text
  , smIdentifier :: T.Text
  , smCreator :: T.Text
  , smCopyright :: T.Text
  , smUrl :: T.Text
  , smType :: T.Text
  }

newtype SDLException = SDLException T.Text
  deriving (Show)

instance Exception SDLException

-- TODO set app metadata properties
runSDLRenderer
  :: forall es a
   . (IOE :> es, Log :> es, Concurrent :> es)
  => Vec2 Int
  -- ^ The size of the window to create.
  -> T.Text
  -- ^ The name of the window.
  -> SDLMeta
  -- ^ The SDL application metadata.
  -> Eff (Render SDL : es) a
  -- ^ The effect to run.
  -> Eff es a
runSDLRenderer (Vec2 width height) title meta = reinterpret_ runSDL $ \case
  Clear -> clear'
  WaitFrame -> waitFrame'
  Present -> present'
  LoadTexture path -> loadTexture' path
  DrawTexture tex dst -> drawTexture' tex dst
  where
    runSDL
      :: Eff (Reader SDLContext : es) a
      -> Eff es a
    runSDL eff = do
      bracket_ openSDL closeSDL $ do
        liftIO $ setMetadata meta
        bracket openWindow closeWindow $ \win -> do
          bracket (openRenderer win) closeRenderer $ \ren -> do
            runReader (SDLContext win ren) eff

    -- Open the SDL context.
    openSDL = do
      logInfo "Acquiring SDL context"
      initSuccess <- liftIO $ F.sdlInit (F.SDL_INIT_VIDEO .|. F.SDL_INIT_EVENTS)
      unless (toBool initSuccess) $ throwIO $ SDLException "Failed to initialize SDL"

    -- Close the SDL context.
    closeSDL = do
      logInfo "Closing SDL context"
      liftIO F.sdlQuit

    -- Open the SDL window.
    openWindow = do
      logInfo "Initializing SDL window"
      let flags = F.SDL_WINDOW_TRANSPARENT .|. F.SDL_WINDOW_BORDERLESS
      win <-
        liftIO
          ( T.withCString title $ \title' ->
              F.sdlCreateWindow title' (fromIntegral width) (fromIntegral height) flags
          )
      if win == nullPtr
        then throwIO $ SDLException "Failed to initialize window"
        else return win

    -- Close the SDL window.
    closeWindow win = do
      logInfo "Closing SDL window"
      liftIO $ F.sdlDestroyWindow win

    -- Open the SDL renderer.
    openRenderer win = do
      logInfo "Initializing SDL renderer"
      ren <- liftIO (F.sdlCreateRenderer win nullPtr)
      if ren == nullPtr
        then throwIO $ SDLException "Failed to initialize renderer"
        else return ren

    -- Close the SDL renderer.
    closeRenderer ren = do
      logInfo "Closing SDL renderer"
      liftIO $ F.sdlDestroyRenderer ren

setMetadata :: SDLMeta -> IO ()
setMetadata meta = do
  -- Mapping from fields on the metadata struct to the property strings
  let metadataProps =
        [ (smName, F.sdlPropAppMetadataNameString)
        , (smVersion, F.sdlPropAppMetadataVersionString)
        , (smIdentifier, F.sdlPropAppMetadataIdentifierString)
        , (smCreator, F.sdlPropAppMetadataCreatorString)
        , (smCopyright, F.sdlPropAppMetadataCopyrightString)
        , (smUrl, F.sdlPropAppMetadataUrlString)
        , (smType, F.sdlPropAppMetadataTypeString)
        ]
  forM_ metadataProps $ \(field, prop) ->
    T.withCString (field meta) $ F.sdlSetAppMetadataProperty prop

clear'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => Eff es ()
clear' = do
  ren <- asks scRenderer
  _ <- liftIO $ F.sdlSetRenderDrawColor ren 0 0 0 0
  result <- liftIO $ F.sdlRenderClear ren
  unless (toBool result) $ logWarn "SDL failed to clear"

-- TODO check out different options for concurrency, there might be a better way
-- to utilize Concurrent effect here
waitFrame' :: Concurrent :> es => Eff es ()
waitFrame' = threadDelay 1000000

present'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => Eff es ()
present' = do
  ren <- asks scRenderer
  result <- liftIO $ F.sdlRenderPresent ren
  unless (toBool result) $ logWarn "SDL failed to present frame"

-- TODO verify that the ForeignPtr setup works properly
loadTexture'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => T.Text
  -> Eff es (Texture SDL)
loadTexture' path = do
  -- TODO store the texture to free before closing renderer?
  ren <- asks scRenderer
  logInfo $ "Creating texture: " <> path
  -- NOTE will this break on windows where the character encoding is different?
  -- might need to use OsPath
  tex <- liftIO $ T.withCString path $ \path' -> F.imgLoadTexture ren path'
  foreignTex <- liftIO $ newForeignPtr F.sdlDestroyTexture' tex
  return $ Texture path foreignTex

drawTexture'
  :: (Reader SDLContext :> es, Log :> es, IOE :> es)
  => Texture SDL
  -> Rect Float
  -> Eff es ()
drawTexture' (Texture meta tex) (Rect x y w h) = do
  ren <- asks scRenderer
  result <-
    liftIO $
      withForeignPtr tex $ \texPtr ->
        with
          (F.SDLFRect (CFloat x) (CFloat y) (CFloat w) (CFloat h))
          (F.sdlRenderTexture ren texPtr nullPtr)
  unless (toBool result) $
    logWarn $
      "SDL failed to render texture" <> meta
