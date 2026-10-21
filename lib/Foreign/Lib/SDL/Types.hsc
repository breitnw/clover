{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}
{-# OPTIONS_GHC -Wno-missing-signatures #-}

{- |
Module      : Foreign.Lib.SDL.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Supporting types (and patterns) for SDL FFI.
-}

module Foreign.Lib.SDL.Types where

import Foreign (Word32, Word64, Storable(..), Bits)
import Foreign.C (CFloat)

import Foreign.TH
import Foreign.Util

#include <SDL3/SDL.h>

-- NOTE ormolu/fourmolu doesn't seem to work here, which is probably good,
-- since I get to align stuff!

-- Thank god for emacs macros...

-- SDL3.Init -------------------------------------------------------------------

newtype SDLInitFlags = SDLInitFlags Word32
  deriving (Eq, Bits)

pattern SDL_INIT_AUDIO                     = SDLInitFlags (#const SDL_INIT_AUDIO)
pattern SDL_INIT_VIDEO                     = SDLInitFlags (#const SDL_INIT_VIDEO)
pattern SDL_INIT_JOYSTICK                  = SDLInitFlags (#const SDL_INIT_JOYSTICK)
pattern SDL_INIT_HAPTIC                    = SDLInitFlags (#const SDL_INIT_HAPTIC)
pattern SDL_INIT_GAMEPAD                   = SDLInitFlags (#const SDL_INIT_GAMEPAD)
pattern SDL_INIT_EVENTS                    = SDLInitFlags (#const SDL_INIT_EVENTS) 
pattern SDL_INIT_SENSOR                    = SDLInitFlags (#const SDL_INIT_SENSOR) 
pattern SDL_INIT_CAMERA                    = SDLInitFlags (#const SDL_INIT_CAMERA) 

-- NOTE we can't actually have address literals in patterns, or else GHC blows
-- up. So, these are just top level definitions

sdlPropAppMetadataNameString               = $(ccstring #const_str SDL_PROP_APP_METADATA_NAME_STRING)
sdlPropAppMetadataVersionString            = $(ccstring #const_str SDL_PROP_APP_METADATA_VERSION_STRING)
sdlPropAppMetadataIdentifierString         = $(ccstring #const_str SDL_PROP_APP_METADATA_IDENTIFIER_STRING)
sdlPropAppMetadataCreatorString            = $(ccstring #const_str SDL_PROP_APP_METADATA_CREATOR_STRING)
sdlPropAppMetadataCopyrightString          = $(ccstring #const_str SDL_PROP_APP_METADATA_COPYRIGHT_STRING)
sdlPropAppMetadataUrlString                = $(ccstring #const_str SDL_PROP_APP_METADATA_URL_STRING)
sdlPropAppMetadataTypeString               = $(ccstring #const_str SDL_PROP_APP_METADATA_TYPE_STRING)


-- SDL3.Video ------------------------------------------------------------------

data SDLWindow

newtype SDLWindowFlags = SDLWindowFlags Word64
  deriving (Eq, Bits)

pattern SDL_WINDOW_FULLSCREEN              = SDLWindowFlags (#const SDL_WINDOW_FULLSCREEN)
pattern SDL_WINDOW_OPENGL                  = SDLWindowFlags (#const SDL_WINDOW_OPENGL)
pattern SDL_WINDOW_OCCLUDED                = SDLWindowFlags (#const SDL_WINDOW_OCCLUDED)
pattern SDL_WINDOW_HIDDEN                  = SDLWindowFlags (#const SDL_WINDOW_HIDDEN)
pattern SDL_WINDOW_BORDERLESS              = SDLWindowFlags (#const SDL_WINDOW_BORDERLESS)
pattern SDL_WINDOW_RESIZABLE               = SDLWindowFlags (#const SDL_WINDOW_RESIZABLE)
pattern SDL_WINDOW_MINIMIZED               = SDLWindowFlags (#const SDL_WINDOW_MINIMIZED)
pattern SDL_WINDOW_MAXIMIZED               = SDLWindowFlags (#const SDL_WINDOW_MAXIMIZED)
pattern SDL_WINDOW_MOUSE_GRABBED           = SDLWindowFlags (#const SDL_WINDOW_MOUSE_GRABBED)
pattern SDL_WINDOW_INPUT_FOCUS             = SDLWindowFlags (#const SDL_WINDOW_INPUT_FOCUS)
pattern SDL_WINDOW_MOUSE_FOCUS             = SDLWindowFlags (#const SDL_WINDOW_MOUSE_FOCUS)
pattern SDL_WINDOW_EXTERNAL                = SDLWindowFlags (#const SDL_WINDOW_EXTERNAL)
pattern SDL_WINDOW_MODAL                   = SDLWindowFlags (#const SDL_WINDOW_MODAL)
pattern SDL_WINDOW_HIGH_PIXEL_DENSITY      = SDLWindowFlags (#const SDL_WINDOW_HIGH_PIXEL_DENSITY)
pattern SDL_WINDOW_MOUSE_CAPTURE           = SDLWindowFlags (#const SDL_WINDOW_MOUSE_CAPTURE)
pattern SDL_WINDOW_MOUSE_RELATIVE_MODE     = SDLWindowFlags (#const SDL_WINDOW_MOUSE_RELATIVE_MODE)
pattern SDL_WINDOW_ALWAYS_ON_TOP           = SDLWindowFlags (#const SDL_WINDOW_ALWAYS_ON_TOP)
pattern SDL_WINDOW_UTILITY                 = SDLWindowFlags (#const SDL_WINDOW_UTILITY)
pattern SDL_WINDOW_TOOLTIP                 = SDLWindowFlags (#const SDL_WINDOW_TOOLTIP)
pattern SDL_WINDOW_POPUP_MENU              = SDLWindowFlags (#const SDL_WINDOW_POPUP_MENU)
pattern SDL_WINDOW_KEYBOARD_GRABBED        = SDLWindowFlags (#const SDL_WINDOW_KEYBOARD_GRABBED)
pattern SDL_WINDOW_FILL_DOCUMENT           = SDLWindowFlags (#const SDL_WINDOW_FILL_DOCUMENT)
pattern SDL_WINDOW_VULKAN                  = SDLWindowFlags (#const SDL_WINDOW_VULKAN)
pattern SDL_WINDOW_METAL                   = SDLWindowFlags (#const SDL_WINDOW_METAL)
pattern SDL_WINDOW_TRANSPARENT             = SDLWindowFlags (#const SDL_WINDOW_TRANSPARENT)
pattern SDL_WINDOW_NOT_FOCUSABLE           = SDLWindowFlags (#const SDL_WINDOW_NOT_FOCUSABLE)

-- SDL3.Surface ----------------------------------------------------------------

data SDLSurface

-- SDL3.Render -----------------------------------------------------------------

data SDLRenderer
data SDLTexture

newtype SDLPixelFormat = SDLPixelFormat Word64
  deriving (Eq, Bits)

pattern SDL_PIXELFORMAT_UNKNOWN            = SDLPixelFormat (#const SDL_PIXELFORMAT_UNKNOWN)
pattern SDL_PIXELFORMAT_INDEX1LSB          = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX1LSB)
pattern SDL_PIXELFORMAT_INDEX1MSB          = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX1MSB)
pattern SDL_PIXELFORMAT_INDEX2LSB          = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX2LSB)
pattern SDL_PIXELFORMAT_INDEX2MSB          = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX2MSB)
pattern SDL_PIXELFORMAT_INDEX4LSB          = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX4LSB)
pattern SDL_PIXELFORMAT_INDEX4MSB          = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX4MSB)
pattern SDL_PIXELFORMAT_INDEX8             = SDLPixelFormat (#const SDL_PIXELFORMAT_INDEX8)
pattern SDL_PIXELFORMAT_RGB332             = SDLPixelFormat (#const SDL_PIXELFORMAT_RGB332)
pattern SDL_PIXELFORMAT_XRGB4444           = SDLPixelFormat (#const SDL_PIXELFORMAT_XRGB4444)
pattern SDL_PIXELFORMAT_XBGR4444           = SDLPixelFormat (#const SDL_PIXELFORMAT_XBGR4444)
pattern SDL_PIXELFORMAT_XRGB1555           = SDLPixelFormat (#const SDL_PIXELFORMAT_XRGB1555)
pattern SDL_PIXELFORMAT_XBGR1555           = SDLPixelFormat (#const SDL_PIXELFORMAT_XBGR1555)
pattern SDL_PIXELFORMAT_ARGB4444           = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB4444)
pattern SDL_PIXELFORMAT_RGBA4444           = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBA4444)
pattern SDL_PIXELFORMAT_ABGR4444           = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR4444)
pattern SDL_PIXELFORMAT_BGRA4444           = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRA4444)
pattern SDL_PIXELFORMAT_ARGB1555           = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB1555)
pattern SDL_PIXELFORMAT_RGBA5551           = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBA5551)
pattern SDL_PIXELFORMAT_ABGR1555           = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR1555)
pattern SDL_PIXELFORMAT_BGRA5551           = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRA5551)
pattern SDL_PIXELFORMAT_RGB565             = SDLPixelFormat (#const SDL_PIXELFORMAT_RGB565)
pattern SDL_PIXELFORMAT_BGR565             = SDLPixelFormat (#const SDL_PIXELFORMAT_BGR565)
pattern SDL_PIXELFORMAT_RGB24              = SDLPixelFormat (#const SDL_PIXELFORMAT_RGB24)
pattern SDL_PIXELFORMAT_BGR24              = SDLPixelFormat (#const SDL_PIXELFORMAT_BGR24)
pattern SDL_PIXELFORMAT_XRGB8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_XRGB8888)
pattern SDL_PIXELFORMAT_RGBX8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBX8888)
pattern SDL_PIXELFORMAT_XBGR8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_XBGR8888)
pattern SDL_PIXELFORMAT_BGRX8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRX8888)
pattern SDL_PIXELFORMAT_ARGB8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB8888)
pattern SDL_PIXELFORMAT_RGBA8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBA8888)
pattern SDL_PIXELFORMAT_ABGR8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR8888)
pattern SDL_PIXELFORMAT_BGRA8888           = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRA8888)
pattern SDL_PIXELFORMAT_XRGB2101010        = SDLPixelFormat (#const SDL_PIXELFORMAT_XRGB2101010)
pattern SDL_PIXELFORMAT_XBGR2101010        = SDLPixelFormat (#const SDL_PIXELFORMAT_XBGR2101010)
pattern SDL_PIXELFORMAT_ARGB2101010        = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB2101010)
pattern SDL_PIXELFORMAT_ABGR2101010        = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR2101010)
pattern SDL_PIXELFORMAT_RGB48              = SDLPixelFormat (#const SDL_PIXELFORMAT_RGB48)
pattern SDL_PIXELFORMAT_BGR48              = SDLPixelFormat (#const SDL_PIXELFORMAT_BGR48)
pattern SDL_PIXELFORMAT_RGBA64             = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBA64)
pattern SDL_PIXELFORMAT_ARGB64             = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB64)
pattern SDL_PIXELFORMAT_BGRA64             = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRA64)
pattern SDL_PIXELFORMAT_ABGR64             = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR64)
pattern SDL_PIXELFORMAT_RGB48_FLOAT        = SDLPixelFormat (#const SDL_PIXELFORMAT_RGB48_FLOAT)
pattern SDL_PIXELFORMAT_BGR48_FLOAT        = SDLPixelFormat (#const SDL_PIXELFORMAT_BGR48_FLOAT)
pattern SDL_PIXELFORMAT_RGBA64_FLOAT       = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBA64_FLOAT)
pattern SDL_PIXELFORMAT_ARGB64_FLOAT       = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB64_FLOAT)
pattern SDL_PIXELFORMAT_BGRA64_FLOAT       = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRA64_FLOAT)
pattern SDL_PIXELFORMAT_ABGR64_FLOAT       = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR64_FLOAT)
pattern SDL_PIXELFORMAT_RGB96_FLOAT        = SDLPixelFormat (#const SDL_PIXELFORMAT_RGB96_FLOAT)
pattern SDL_PIXELFORMAT_BGR96_FLOAT        = SDLPixelFormat (#const SDL_PIXELFORMAT_BGR96_FLOAT)
pattern SDL_PIXELFORMAT_RGBA128_FLOAT      = SDLPixelFormat (#const SDL_PIXELFORMAT_RGBA128_FLOAT)
pattern SDL_PIXELFORMAT_ARGB128_FLOAT      = SDLPixelFormat (#const SDL_PIXELFORMAT_ARGB128_FLOAT)
pattern SDL_PIXELFORMAT_BGRA128_FLOAT      = SDLPixelFormat (#const SDL_PIXELFORMAT_BGRA128_FLOAT)
pattern SDL_PIXELFORMAT_ABGR128_FLOAT      = SDLPixelFormat (#const SDL_PIXELFORMAT_ABGR128_FLOAT)

-- SDL3.Rect -------------------------------------------------------------------

data SDLFRect = SDLFRect
  { sdlFRectX :: {-# UNPACK #-} !CFloat
  , sdlFRectY :: {-# UNPACK #-} !CFloat
  , sdlFRectW :: {-# UNPACK #-} !CFloat
  , sdlFRectH :: {-# UNPACK #-} !CFloat
  } deriving (Eq, Show, Read)

instance Storable SDLFRect where
  sizeOf _ = #{size SDL_FRect}
  alignment _ = #{alignment SDL_FRect}
  peek ptr = do
    x <- #{peek SDL_FRect, x} ptr
    y <- #{peek SDL_FRect, y} ptr
    w <- #{peek SDL_FRect, w} ptr
    h <- #{peek SDL_FRect, h} ptr
    return $ SDLFRect x y w h
  poke ptr (SDLFRect x y w h) = do
    #{poke SDL_FRect, x} ptr x
    #{poke SDL_FRect, y} ptr y
    #{poke SDL_FRect, w} ptr w
    #{poke SDL_FRect, h} ptr h

-- SDL3.IOStream ---------------------------------------------------------------

data SDLIOStream
