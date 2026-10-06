{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE CApiFFI #-}
{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}

{- HLINT ignore "Use camelCase" -}

{- |
Module      : Effectful.Foreign.SDL
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Raw (and effect-wrapped) FFI for SDL.
-}
module Effectful.Foreign.SDL (
  SDL,
  runSDL,

  -- * SDL3.Log
  c_sdlLogInfo,
  c_sdlLogWarn,
  c_sdlLogError,

  -- * SDL3.Init
  SDLInitFlags,
  pattern SDL_INIT_AUDIO,
  pattern SDL_INIT_VIDEO,
  pattern SDL_INIT_JOYSTICK,
  pattern SDL_INIT_HAPTIC,
  pattern SDL_INIT_GAMEPAD,
  pattern SDL_INIT_EVENTS,
  pattern SDL_INIT_SENSOR,
  pattern SDL_INIT_CAMERA,
  c_sdlInit,
  c_sdlQuit,
  c_sdlSetAppMetadataProperty,
  c_sdlGetAppMetadataProperty,

  -- * SDL3.Video
  SDLWindow,
  SDLWindowFlags,
  pattern SDL_WINDOW_FULLSCREEN,
  pattern SDL_WINDOW_OPENGL,
  pattern SDL_WINDOW_OCCLUDED,
  pattern SDL_WINDOW_HIDDEN,
  pattern SDL_WINDOW_BORDERLESS,
  pattern SDL_WINDOW_RESIZABLE,
  pattern SDL_WINDOW_MINIMIZED,
  pattern SDL_WINDOW_MAXIMIZED,
  pattern SDL_WINDOW_MOUSE_GRABBED,
  pattern SDL_WINDOW_INPUT_FOCUS,
  pattern SDL_WINDOW_MOUSE_FOCUS,
  pattern SDL_WINDOW_EXTERNAL,
  pattern SDL_WINDOW_MODAL,
  pattern SDL_WINDOW_HIGH_PIXEL_DENSITY,
  pattern SDL_WINDOW_MOUSE_CAPTURE,
  pattern SDL_WINDOW_MOUSE_RELATIVE_MODE,
  pattern SDL_WINDOW_ALWAYS_ON_TOP,
  pattern SDL_WINDOW_UTILITY,
  pattern SDL_WINDOW_TOOLTIP,
  pattern SDL_WINDOW_POPUP_MENU,
  pattern SDL_WINDOW_KEYBOARD_GRABBED,
  pattern SDL_WINDOW_FILL_DOCUMENT,
  pattern SDL_WINDOW_VULKAN,
  pattern SDL_WINDOW_METAL,
  pattern SDL_WINDOW_TRANSPARENT,
  pattern SDL_WINDOW_NOT_FOCUSABLE,
  c_sdlCreateWindow,
  c_sdlDestroyWindow,
  
  -- * SDL3.Render
  SDLRenderer,
  c_sdlCreateRenderer,
  c_sdlDestroyRenderer,
  c_sdlRenderClear,
) where

#include <SDL3/SDL.h>

import Foreign (Ptr, Word32, Word64)
import Foreign.C (CBool (..), CChar, CInt (..), CString)
import Foreign.C.ConstPtr (ConstPtr (..))

import Effectful
import Effectful.Dispatch.Static

-- EFFECT ----------------------------------------------------------------------

-- XXX should this even be effectful? probably not worth it

data SDL :: Effect

type instance DispatchOf SDL = Static WithSideEffects
data instance StaticRep SDL = SDL

-- | Run the 'SDL' effect
runSDL :: IOE :> es => Eff (SDL : es) a -> Eff es a
runSDL = evalStaticRep SDL

-- SDL3.Log --------------------------------------------------------------------

-- NOTE Since the above logging take varargs, allowing any format specifiers is
-- a security risk. Instead, the FFI calls each accept 2 strings:
-- 1. The format string, assumed to be PRE-CONFIGURED by the logging library to
--    "%s", or something along those lines
-- 2. The actual message to print

-- The solution kinda sucks, but given a correct logging library, it's safe...

foreign import capi unsafe "SDL3/SDL.h SDL_LogInfo"
  c_sdlLogInfo :: CInt -> CString -> CString -> IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_LogWarn"
  c_sdlLogWarn :: CInt -> CString -> CString -> IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_LogError"
  c_sdlLogError :: CInt -> CString -> CString -> IO ()

-- SDL3.Init -------------------------------------------------------------------

type SDLInitFlags = Word32

pattern SDL_INIT_AUDIO = (#const SDL_INIT_AUDIO) :: SDLInitFlags
pattern SDL_INIT_VIDEO = (#const SDL_INIT_VIDEO) :: SDLInitFlags
pattern SDL_INIT_JOYSTICK = (#const SDL_INIT_JOYSTICK) :: SDLInitFlags
pattern SDL_INIT_HAPTIC = (#const SDL_INIT_HAPTIC) :: SDLInitFlags
pattern SDL_INIT_GAMEPAD = (#const SDL_INIT_GAMEPAD) :: SDLInitFlags
pattern SDL_INIT_EVENTS = (#const SDL_INIT_EVENTS) :: SDLInitFlags
pattern SDL_INIT_SENSOR = (#const SDL_INIT_SENSOR) :: SDLInitFlags
pattern SDL_INIT_CAMERA = (#const SDL_INIT_CAMERA) :: SDLInitFlags

foreign import capi unsafe "SDL3/SDL.h SDL_Init" c_sdlInit :: Word32 -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_Quit" c_sdlQuit :: IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_SetAppMetadataProperty"
  c_sdlSetAppMetadataProperty :: CString -> CString -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_GetAppMetadataProperty" -- This is freed by SDL
  c_sdlGetAppMetadataProperty :: CString -> IO (ConstPtr CChar) -- XXX constptr cchar is ugly, but avoids error. need to use unConstPtr to get the CString

-- TODO remove
-- propAppMetadataName = "SDL.app.metadata.name"
-- propAppMetadataIdentifier = "SDL.app.metadata.identifier"
-- propAppMetadataCreator = "SDL.app.metadata.creator"
-- propAppMetadataCopyright = "SDL.app.metadata.copyright"
-- propAppMetadataUrl = "SDL.app.metadata.url"
-- propAppMetadataType = "SDL.app.metadata.type"

-- SDL3.Video ------------------------------------------------------------------

data SDLWindow

type SDLWindowFlags = Word64

pattern SDL_WINDOW_FULLSCREEN = (#{const SDL_WINDOW_FULLSCREEN}) :: SDLWindowFlags
pattern SDL_WINDOW_OPENGL = (#{const SDL_WINDOW_OPENGL}) :: SDLWindowFlags
pattern SDL_WINDOW_OCCLUDED = (#{const SDL_WINDOW_OCCLUDED}) :: SDLWindowFlags
pattern SDL_WINDOW_HIDDEN = (#{const SDL_WINDOW_HIDDEN}) :: SDLWindowFlags
pattern SDL_WINDOW_BORDERLESS = (#{const SDL_WINDOW_BORDERLESS}) :: SDLWindowFlags
pattern SDL_WINDOW_RESIZABLE = (#{const SDL_WINDOW_RESIZABLE}) :: SDLWindowFlags
pattern SDL_WINDOW_MINIMIZED = (#{const SDL_WINDOW_MINIMIZED}) :: SDLWindowFlags
pattern SDL_WINDOW_MAXIMIZED = (#{const SDL_WINDOW_MAXIMIZED}) :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_GRABBED = (#{const SDL_WINDOW_MOUSE_GRABBED}) :: SDLWindowFlags
pattern SDL_WINDOW_INPUT_FOCUS = (#{const SDL_WINDOW_INPUT_FOCUS}) :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_FOCUS = (#{const SDL_WINDOW_MOUSE_FOCUS}) :: SDLWindowFlags
pattern SDL_WINDOW_EXTERNAL = (#{const SDL_WINDOW_EXTERNAL}) :: SDLWindowFlags
pattern SDL_WINDOW_MODAL = (#{const SDL_WINDOW_MODAL}) :: SDLWindowFlags
pattern SDL_WINDOW_HIGH_PIXEL_DENSITY = (#{const SDL_WINDOW_HIGH_PIXEL_DENSITY}) :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_CAPTURE = (#{const SDL_WINDOW_MOUSE_CAPTURE}) :: SDLWindowFlags
pattern SDL_WINDOW_MOUSE_RELATIVE_MODE = (#{const SDL_WINDOW_MOUSE_RELATIVE_MODE}) :: SDLWindowFlags
pattern SDL_WINDOW_ALWAYS_ON_TOP = (#{const SDL_WINDOW_ALWAYS_ON_TOP}) :: SDLWindowFlags
pattern SDL_WINDOW_UTILITY = (#{const SDL_WINDOW_UTILITY}) :: SDLWindowFlags
pattern SDL_WINDOW_TOOLTIP = (#{const SDL_WINDOW_TOOLTIP}) :: SDLWindowFlags
pattern SDL_WINDOW_POPUP_MENU = (#{const SDL_WINDOW_POPUP_MENU}) :: SDLWindowFlags
pattern SDL_WINDOW_KEYBOARD_GRABBED = (#{const SDL_WINDOW_KEYBOARD_GRABBED}) :: SDLWindowFlags
pattern SDL_WINDOW_FILL_DOCUMENT = (#{const SDL_WINDOW_FILL_DOCUMENT}) :: SDLWindowFlags
pattern SDL_WINDOW_VULKAN = (#{const SDL_WINDOW_VULKAN}) :: SDLWindowFlags
pattern SDL_WINDOW_METAL = (#{const SDL_WINDOW_METAL}) :: SDLWindowFlags
pattern SDL_WINDOW_TRANSPARENT = (#{const SDL_WINDOW_TRANSPARENT}) :: SDLWindowFlags
pattern SDL_WINDOW_NOT_FOCUSABLE = (#{const SDL_WINDOW_NOT_FOCUSABLE}) :: SDLWindowFlags

foreign import capi "SDL3/SDL.h SDL_CreateWindow"
  c_sdlCreateWindow :: CString -> CInt -> CInt -> SDLWindowFlags -> IO (Ptr SDLWindow)
foreign import capi "SDL3/SDL.h SDL_DestroyWindow"
  c_sdlDestroyWindow :: Ptr SDLWindow -> IO ()

-- TODO setWindowShape and stuff

-- SDL3.Render -----------------------------------------------------------------

data SDLRenderer

foreign import capi "SDL3/SDL.h SDL_CreateRenderer" -- XXX Safe due to window system interaction
  c_sdlCreateRenderer :: Ptr SDLWindow -> CString -> IO (Ptr SDLRenderer)
foreign import capi "SDL3/SDL.h SDL_DestroyRenderer" -- XXX Safe due to potential cleanup
  c_sdlDestroyRenderer :: Ptr SDLRenderer -> IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_RenderClear"
  c_sdlRenderClear :: Ptr SDLRenderer -> IO CBool
