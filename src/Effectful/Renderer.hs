{- |
Module      : Effectful.Renderer
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}

module Effectful.Renderer where

-- TODO Make into an effect?
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
