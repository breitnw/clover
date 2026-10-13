{-# LANGUAGE CApiFFI #-}
{-# LANGUAGE ForeignFunctionInterface #-}

{- |
Module      : Foreign.SDLImage
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Raw FFI for SDL_image.
-}
module Foreign.SDLImage where

import Foreign (Ptr)
import Foreign.C.ConstPtr (ConstPtr (..))

import Foreign.SDL.Types
import Foreign.Util

foreign import capi unsafe "SDL3_image/SDL_image.h IMG_Load"
  imgLoad :: ConstCString -> IO (Ptr SDLSurface)
foreign import capi unsafe "SDL3_image/SDL_image.h IMG_LoadTexture"
  imgLoadTexture :: Ptr SDLRenderer -> ConstCString -> IO (Ptr SDLTexture)
