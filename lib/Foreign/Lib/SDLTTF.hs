{-# LANGUAGE CApiFFI #-}
{-# LANGUAGE ForeignFunctionInterface #-}

{- |
Module      : Foreign.Lib.SDLTTF
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
module Foreign.Lib.SDLTTF where

import Foreign (Ptr, Word8)
import Foreign.C.ConstPtr (ConstPtr (..))

import Foreign.C (CBool (..), CFloat (..), CInt, CSize (..))
import Foreign.Lib.SDL.Types
import Foreign.Util

data TTFFont
data TTFTextEngine
data TTFText

-- Context creation
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_Init"
  ttfInit :: IO CBool
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_Init"
  ttfQuit :: IO ()

-- Font creation
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_OpenFont"
  ttfOpenFont :: ConstCString -> CFloat -> IO (Ptr TTFFont)
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_CloseFont"
  ttfCloseFont :: Ptr TTFFont -> IO ()

-- Engine creation
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_CreateRendererTextEngine"
  ttfCreateRendererTextEngine :: Ptr SDLRenderer -> IO (Ptr TTFTextEngine)
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_DestroyRendererTextEngine"
  ttfDestroyRendererTextEngine :: Ptr TTFTextEngine -> IO ()

-- Text creation
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_CreateText"
  ttfCreateText
    :: Ptr TTFTextEngine -> Ptr TTFFont -> ConstCString -> CSize -> IO (Ptr TTFText)
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_DestroyText"
  ttfDestroyText :: Ptr TTFText -> IO ()

-- Text properties
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_SetTextString"
  ttfSetTextString :: Ptr TTFText -> ConstCString -> CSize -> IO CBool
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_SetTextColor"
  ttfSetTextColor :: Ptr TTFText -> Word8 -> Word8 -> Word8 -> Word8 -> IO CBool
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_GetTextSize"
  ttfGetTextSize :: Ptr TTFText -> Ptr CInt -> Ptr CInt -> IO CBool

-- Text updates and rendering
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_UpdateText"
  ttfUpdateText :: Ptr TTFText -> IO CBool
foreign import capi unsafe "SDL3_ttf/SDL_ttf.h TTF_DrawRendererText"
  ttfDrawRendererText :: Ptr TTFText -> CFloat -> CFloat -> IO CBool
