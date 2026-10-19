{-# LANGUAGE CApiFFI #-}
{-# LANGUAGE ForeignFunctionInterface #-}

{- |
Module      : Foreign.Lib.SDLImage
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Raw FFI for SDL_image.
-}
module Foreign.Lib.SDLImage where

import Foreign (Ptr)
import Foreign.C (CBool (..))
import Foreign.C.ConstPtr (ConstPtr (..))

import Foreign.Lib.SDL.Types
import Foreign.Util

foreign import capi unsafe "SDL3_image/SDL_image.h IMG_Load"
  imgLoad :: ConstCString -> IO (Ptr SDLSurface)
foreign import capi unsafe "SDL3_image/SDL_image.h IMG_Load_IO"
  imgLoadIO :: Ptr SDLIOStream -> CBool -> IO (Ptr SDLSurface)
foreign import capi unsafe "SDL3_image/SDL_image.h IMG_LoadTexture"
  imgLoadTexture :: Ptr SDLRenderer -> ConstCString -> IO (Ptr SDLTexture)
foreign import capi unsafe "SDL3_image/SDL_image.h IMG_LoadTexture_IO"
  imgLoadTextureIO
    :: Ptr SDLRenderer -> Ptr SDLIOStream -> CBool -> IO (Ptr SDLTexture)
