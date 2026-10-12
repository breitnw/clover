{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}
{-# OPTIONS_GHC -Wno-missing-signatures #-}

{- |
Module      : Foreign.SDL.Types
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Supporting types (and patterns) for SDL FFI.
-}

module Foreign.SDL.Types where

import Foreign (Word32, Word64, Storable(..))
import Foreign.C (CFloat, CString)

import Foreign.TH

#include <SDL3/SDL.h>

-- NOTE ormolu/fourmolu doesn't seem to work here, which is probably good,
-- since I get to align stuff!

-- Thank god for emacs macros...

-- SDL3.Init -------------------------------------------------------------------

type SDLInitFlags = Word32

pattern SDL_INIT_AUDIO    = (#const SDL_INIT_AUDIO)    :: SDLInitFlags
pattern SDL_INIT_VIDEO    = (#const SDL_INIT_VIDEO)    :: SDLInitFlags
pattern SDL_INIT_JOYSTICK = (#const SDL_INIT_JOYSTICK) :: SDLInitFlags
pattern SDL_INIT_HAPTIC   = (#const SDL_INIT_HAPTIC)   :: SDLInitFlags
pattern SDL_INIT_GAMEPAD  = (#const SDL_INIT_GAMEPAD)  :: SDLInitFlags
pattern SDL_INIT_EVENTS   = (#const SDL_INIT_EVENTS)   :: SDLInitFlags
pattern SDL_INIT_SENSOR   = (#const SDL_INIT_SENSOR)   :: SDLInitFlags
pattern SDL_INIT_CAMERA   = (#const SDL_INIT_CAMERA)   :: SDLInitFlags

-- NOTE we can't actually have address literals in patterns, or else GHC blows
-- up. So, these are just top level definitions

sdlPropAppMetadataNameString       = $(cstring #const_str SDL_PROP_APP_METADATA_NAME_STRING)       :: CString
sdlPropAppMetadataVersionString    = $(cstring #const_str SDL_PROP_APP_METADATA_VERSION_STRING)    :: CString
sdlPropAppMetadataIdentifierString = $(cstring #const_str SDL_PROP_APP_METADATA_IDENTIFIER_STRING) :: CString
sdlPropAppMetadataCreatorString    = $(cstring #const_str SDL_PROP_APP_METADATA_CREATOR_STRING)    :: CString
sdlPropAppMetadataCopyrightString  = $(cstring #const_str SDL_PROP_APP_METADATA_COPYRIGHT_STRING)  :: CString
sdlPropAppMetadataUrlString        = $(cstring #const_str SDL_PROP_APP_METADATA_URL_STRING)        :: CString
sdlPropAppMetadataTypeString       = $(cstring #const_str SDL_PROP_APP_METADATA_TYPE_STRING)       :: CString


-- SDL3.Video ------------------------------------------------------------------

data SDLWindow

type SDLWindowFlags = Word64

pattern SDL_WINDOW_FULLSCREEN          = (#const SDL_WINDOW_FULLSCREEN)          :: SDLWindowFlags
pattern SDL_WINDOW_OPENGL              = (#const SDL_WINDOW_OPENGL)              :: SDLWindowFlags
pattern SDL_WINDOW_OCCLUDED            = (#const SDL_WINDOW_OCCLUDED)            :: SDLWindowFlags
pattern SDL_WINDOW_HIDDEN              = (#const SDL_WINDOW_HIDDEN)              :: SDLWindowFlags
pattern SDL_WINDOW_BORDERLESS          = (#const SDL_WINDOW_BORDERLESS)          :: SDLWindowFlags
pattern SDL_WINDOW_RESIZABLE           = (#const SDL_WINDOW_RESIZABLE)           :: SDLWindowFlags
pattern SDL_WINDOW_MINIMIZED           = (#const SDL_WINDOW_MINIMIZED)           :: SDLWindowFlags
pattern SDL_WINDOW_MAXIMIZED           = (#const SDL_WINDOW_MAXIMIZED)           :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_GRABBED       = (#const SDL_WINDOW_MOUSE_GRABBED)       :: SDLWindowFlags
pattern SDL_WINDOW_INPUT_FOCUS         = (#const SDL_WINDOW_INPUT_FOCUS)         :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_FOCUS         = (#const SDL_WINDOW_MOUSE_FOCUS)         :: SDLWindowFlags
pattern SDL_WINDOW_EXTERNAL            = (#const SDL_WINDOW_EXTERNAL)            :: SDLWindowFlags
pattern SDL_WINDOW_MODAL               = (#const SDL_WINDOW_MODAL)               :: SDLWindowFlags
pattern SDL_WINDOW_HIGH_PIXEL_DENSITY  = (#const SDL_WINDOW_HIGH_PIXEL_DENSITY)  :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_CAPTURE       = (#const SDL_WINDOW_MOUSE_CAPTURE)       :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_RELATIVE_MODE = (#const SDL_WINDOW_MOUSE_RELATIVE_MODE) :: SDLWindowFlags
pattern SDL_WINDOW_ALWAYS_ON_TOP       = (#const SDL_WINDOW_ALWAYS_ON_TOP)       :: SDLWindowFlags
pattern SDL_WINDOW_UTILITY             = (#const SDL_WINDOW_UTILITY)             :: SDLWindowFlags
pattern SDL_WINDOW_TOOLTIP             = (#const SDL_WINDOW_TOOLTIP)             :: SDLWindowFlags
pattern SDL_WINDOW_POPUP_MENU          = (#const SDL_WINDOW_POPUP_MENU)          :: SDLWindowFlags
pattern SDL_WINDOW_KEYBOARD_GRABBED    = (#const SDL_WINDOW_KEYBOARD_GRABBED)    :: SDLWindowFlags
pattern SDL_WINDOW_FILL_DOCUMENT       = (#const SDL_WINDOW_FILL_DOCUMENT)       :: SDLWindowFlags
pattern SDL_WINDOW_VULKAN              = (#const SDL_WINDOW_VULKAN)              :: SDLWindowFlags
pattern SDL_WINDOW_METAL               = (#const SDL_WINDOW_METAL)               :: SDLWindowFlags
pattern SDL_WINDOW_TRANSPARENT         = (#const SDL_WINDOW_TRANSPARENT)         :: SDLWindowFlags
pattern SDL_WINDOW_NOT_FOCUSABLE       = (#const SDL_WINDOW_NOT_FOCUSABLE)       :: SDLWindowFlags

-- SDL3.Surface ----------------------------------------------------------------

data SDLSurface

-- SDL3.Render -----------------------------------------------------------------

data SDLRenderer
data SDLTexture

type SDLPixelFormat = Word64

pattern SDL_PIXELFORMAT_UNKNOWN       = (#const SDL_PIXELFORMAT_UNKNOWN)       :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX1LSB     = (#const SDL_PIXELFORMAT_INDEX1LSB)     :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX1MSB     = (#const SDL_PIXELFORMAT_INDEX1MSB)     :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX2LSB     = (#const SDL_PIXELFORMAT_INDEX2LSB)     :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX2MSB     = (#const SDL_PIXELFORMAT_INDEX2MSB)     :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX4LSB     = (#const SDL_PIXELFORMAT_INDEX4LSB)     :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX4MSB     = (#const SDL_PIXELFORMAT_INDEX4MSB)     :: SDLPixelFormat
pattern SDL_PIXELFORMAT_INDEX8        = (#const SDL_PIXELFORMAT_INDEX8)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGB332        = (#const SDL_PIXELFORMAT_RGB332)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XRGB4444      = (#const SDL_PIXELFORMAT_XRGB4444)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XBGR4444      = (#const SDL_PIXELFORMAT_XBGR4444)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XRGB1555      = (#const SDL_PIXELFORMAT_XRGB1555)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XBGR1555      = (#const SDL_PIXELFORMAT_XBGR1555)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB4444      = (#const SDL_PIXELFORMAT_ARGB4444)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBA4444      = (#const SDL_PIXELFORMAT_RGBA4444)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR4444      = (#const SDL_PIXELFORMAT_ABGR4444)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRA4444      = (#const SDL_PIXELFORMAT_BGRA4444)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB1555      = (#const SDL_PIXELFORMAT_ARGB1555)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBA5551      = (#const SDL_PIXELFORMAT_RGBA5551)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR1555      = (#const SDL_PIXELFORMAT_ABGR1555)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRA5551      = (#const SDL_PIXELFORMAT_BGRA5551)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGB565        = (#const SDL_PIXELFORMAT_RGB565)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGR565        = (#const SDL_PIXELFORMAT_BGR565)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGB24         = (#const SDL_PIXELFORMAT_RGB24)         :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGR24         = (#const SDL_PIXELFORMAT_BGR24)         :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XRGB8888      = (#const SDL_PIXELFORMAT_XRGB8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBX8888      = (#const SDL_PIXELFORMAT_RGBX8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XBGR8888      = (#const SDL_PIXELFORMAT_XBGR8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRX8888      = (#const SDL_PIXELFORMAT_BGRX8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB8888      = (#const SDL_PIXELFORMAT_ARGB8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBA8888      = (#const SDL_PIXELFORMAT_RGBA8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR8888      = (#const SDL_PIXELFORMAT_ABGR8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRA8888      = (#const SDL_PIXELFORMAT_BGRA8888)      :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XRGB2101010   = (#const SDL_PIXELFORMAT_XRGB2101010)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_XBGR2101010   = (#const SDL_PIXELFORMAT_XBGR2101010)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB2101010   = (#const SDL_PIXELFORMAT_ARGB2101010)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR2101010   = (#const SDL_PIXELFORMAT_ABGR2101010)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGB48         = (#const SDL_PIXELFORMAT_RGB48)         :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGR48         = (#const SDL_PIXELFORMAT_BGR48)         :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBA64        = (#const SDL_PIXELFORMAT_RGBA64)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB64        = (#const SDL_PIXELFORMAT_ARGB64)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRA64        = (#const SDL_PIXELFORMAT_BGRA64)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR64        = (#const SDL_PIXELFORMAT_ABGR64)        :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGB48_FLOAT   = (#const SDL_PIXELFORMAT_RGB48_FLOAT)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGR48_FLOAT   = (#const SDL_PIXELFORMAT_BGR48_FLOAT)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBA64_FLOAT  = (#const SDL_PIXELFORMAT_RGBA64_FLOAT)  :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB64_FLOAT  = (#const SDL_PIXELFORMAT_ARGB64_FLOAT)  :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRA64_FLOAT  = (#const SDL_PIXELFORMAT_BGRA64_FLOAT)  :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR64_FLOAT  = (#const SDL_PIXELFORMAT_ABGR64_FLOAT)  :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGB96_FLOAT   = (#const SDL_PIXELFORMAT_RGB96_FLOAT)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGR96_FLOAT   = (#const SDL_PIXELFORMAT_BGR96_FLOAT)   :: SDLPixelFormat
pattern SDL_PIXELFORMAT_RGBA128_FLOAT = (#const SDL_PIXELFORMAT_RGBA128_FLOAT) :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ARGB128_FLOAT = (#const SDL_PIXELFORMAT_ARGB128_FLOAT) :: SDLPixelFormat
pattern SDL_PIXELFORMAT_BGRA128_FLOAT = (#const SDL_PIXELFORMAT_BGRA128_FLOAT) :: SDLPixelFormat
pattern SDL_PIXELFORMAT_ABGR128_FLOAT = (#const SDL_PIXELFORMAT_ABGR128_FLOAT) :: SDLPixelFormat

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
