{- |
Module      : Effectful.Renderer.Handler.SDL
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Effectful.Renderer.Handler.SDL () where

import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Log qualified as Log
import Effectful.Network.MPD qualified as MPD
import SDL3.Surface qualified as SDL

import Effectful.Renderer.Types

-- EFFECT HANDLER --------------------------------------------------------------

data SDL

instance RenderBackend SDL where
  type Texture SDL = SDL.SDLSurface

withSDLRenderer
  :: (IOE :> es, Log.Log :> es) -- IOE needed for image loading as well as MPD
  => MPD.Host
  -> MPD.Port
  -> MPD.Password
  -> Eff (Renderer SDL : es) a
  -> Eff es (Either MPD.MPDError a)
withSDLRenderer host port pw = reinterpret_ runMPD $ \case
  CurrentSong -> fmap asCloverSong <$> MPD.currentSong
  GetSong songId -> getSong' songId
  GetArtwork songId -> getArtwork' songId
  SendCommand cmd -> sendCommand' cmd
  where
    runMPD = MPD.withEMPDEx host port pw

type Texture = Ptr SDLSurface

-- TODO Make into an effect?

-- CONVERTERS ------------------------------------------------------------------

-- | Convert an STB image to an SDL surface
--
-- based on https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L337
toSurface :: STB.Image -> IO (Maybe (Ptr SDLSurface))
toSurface bmp = BMP.withBitmap bmp go
  where
    go (w, h) nchn _padding ptr =
      sdlCreateSurfaceFrom
        (fromIntegral w)
        (fromIntegral h)
        format
        (castPtr ptr)
        (fromIntegral pitch)
      where
        format = case nchn of
          3 -> SDL_PIXELFORMAT_RGB24
          4 -> SDL_PIXELFORMAT_RGBA32
          _ -> SDL_PIXELFORMAT_RGB24 -- TODO MAKE UNREACHABLE
        pitch = nchn * w

{-

import Control.Monad.Error.Class
import Control.Monad.Except
import Control.Monad.Reader
import qualified SDL3 as SDL

-- | Rendering context of the application.
data AppContext = AppContext
  { acWindow :: SDL.SDLWindow
  , acRenderer :: SDL.SDLRenderer
  }

-- | Signal to free SDL resources and exit from the application.
data AppExit = AppError String | AppSuccess

newtype App a = AppT
  { runApp :: ((ExceptT AppExit) (ReaderT AppContext IO)) a
  }
  deriving
    ( Functor
    , Applicative
    , Monad
    , MonadReader AppContext
    , MonadError AppExit
    , MonadIO
    )

instance MonadFail App where
  fail = throwError . AppError

-- | Retrieve the application's window.
currentWindow :: MonadReader AppContext m => m SDL.SDLWindow
currentWindow = asks acWindow

-- | Retrieve the application's renderer.
currentRenderer :: MonadReader AppContext m => m SDL.SDLRenderer
currentRenderer = asks acRenderer
-}
