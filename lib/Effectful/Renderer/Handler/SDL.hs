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

import Control.Monad (forM_, unless, when)
import Foreign (Bits ((.|.)), Ptr, castPtr, toBool, with)
import Foreign.C (CFloat (..))
import Foreign.Marshal (fromBool)

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Concurrent
import Effectful.Dispatch.Dynamic
import Effectful.Exception
import Effectful.Reader.Static

import Effectful.Logger
import Effectful.Renderer.Effect
import Effectful.Renderer.Types
import Foreign.Lib.SDL qualified as F
import Foreign.Lib.SDLImage qualified as F
import Foreign.Util
import Util

-- EFFECT HANDLER --------------------------------------------------------------

-- | An empty type representing the SDL render backend.
data SDL

-- | Printable metadata for a texture.
newtype TextureMeta = TextureMeta T.Text

-- | A SDL texture comes with a name and data
-- NOTE designated metadata type
data instance Texture SDL = Texture TextureMeta (Ptr F.SDLTexture)

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
  LoadTextureFile path -> loadTextureFile' path
  LoadTextureBytes bytes -> loadTextureBytes' bytes
  DestroyTexture tex -> destroyTexture' tex
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
      win <- liftIO $ withCString title $ \title' ->
        F.sdlCreateWindow
          title'
          (fromIntegral width)
          (fromIntegral height)
          flags
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
    withCString (field meta) $ F.sdlSetAppMetadataProperty prop

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

loadTextureFile'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => Path
  -> Eff es (Texture SDL)
loadTextureFile' (Path pathText) = do
  ren <- asks scRenderer
  logInfo $ "Creating texture: " <> pathText
  -- NOTE will this break on windows where the character encoding is different?
  -- might need to use OsPath
  tex <- liftIO $ withCString pathText $ F.imgLoadTexture ren
  -- Make sure the texture was loaded properly
  when (tex == nullPtr) $
    throwIO $
      SDLException "Failed to initialize renderer"
  return $ Texture (TextureMeta pathText) tex

loadTextureBytes'
  :: ( Reader SDLContext :> es
     , Log :> es
     , IOE :> es
     )
  => BS.ByteString
  -> Eff es (Texture SDL)
loadTextureBytes' bytes = do
  let name = "<bytes>"
  ren <- asks scRenderer
  logInfo $ "Creating texture: " <> name
  tex <- liftIO $ BS.useAsCStringLen bytes $ \(cstring, len) -> do
    -- castptr is sus
    ioStream <- F.sdlIOFromMem (castPtr cstring) (fromIntegral len)
    if ioStream == nullPtr
      then return nullPtr -- kinda yucky, but whatever
      else F.imgLoadTextureIO ren ioStream (fromBool True)
  -- Make sure the texture was loaded properly
  when (tex == nullPtr) $
    throwIO $
      SDLException "Failed to initialize renderer"
  return $ Texture (TextureMeta name) tex

destroyTexture' :: (Log :> es, IOE :> es) => Texture SDL -> Eff es ()
destroyTexture' (Texture (TextureMeta meta) tex) = do
  logInfo $ "Destroying texture: " <> meta
  liftIO $ F.sdlDestroyTexture tex

drawTexture'
  :: (Reader SDLContext :> es, Log :> es, IOE :> es)
  => Texture SDL
  -> Rect Float
  -> Eff es ()
drawTexture' (Texture (TextureMeta meta) tex) (Rect x y w h) = do
  ren <- asks scRenderer
  result <-
    liftIO $
      with
        (F.SDLFRect (CFloat x) (CFloat y) (CFloat w) (CFloat h))
        (F.sdlRenderTexture ren tex nullPtr)
  unless (toBool result) $
    logWarn $
      "SDL failed to render texture" <> meta
