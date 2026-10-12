{-# LANGUAGE CApiFFI #-}
{-# LANGUAGE ForeignFunctionInterface #-}

{- |
Module      : Foreign.SDL.FFI
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

SDL functions.
-}
module Foreign.SDL.FFI where

import Foreign (FunPtr, Ptr, Word8)
import Foreign.C (CBool (..), CChar, CFloat, CInt (..), CString)
import Foreign.C.ConstPtr (ConstPtr (..))

import Foreign.SDL.Types

-- SDL3.Log --------------------------------------------------------------------

-- NOTE Since the above logging take varargs, allowing any format specifiers is
-- a security risk. Instead, the FFI calls each accept 2 strings:
-- 1. The format string, assumed to be PRE-CONFIGURED by the logging library to
--    "%s", or something along those lines
-- 2. The actual message to print

-- The solution kinda sucks, but given a correct logging library, it's safe...

foreign import capi unsafe "SDL3/SDL.h SDL_LogInfo"
  sdlLogInfo :: CInt -> CString -> CString -> IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_LogWarn"
  sdlLogWarn :: CInt -> CString -> CString -> IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_LogError"
  sdlLogError :: CInt -> CString -> CString -> IO ()

-- SDL3.Init -------------------------------------------------------------------

foreign import capi unsafe "SDL3/SDL.h SDL_Init"
  sdlInit :: SDLInitFlags -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_Quit" sdlQuit :: IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_SetAppMetadataProperty"
  sdlSetAppMetadataProperty :: CString -> CString -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_GetAppMetadataProperty"
  sdlGetAppMetadataProperty :: CString -> IO (ConstPtr CChar)

--- SDL3.Video -----------------------------------------------------------------

foreign import capi "SDL3/SDL.h SDL_CreateWindow"
  sdlCreateWindow
    :: CString -> CInt -> CInt -> SDLWindowFlags -> IO (Ptr SDLWindow)
foreign import capi "SDL3/SDL.h SDL_DestroyWindow"
  sdlDestroyWindow :: Ptr SDLWindow -> IO ()

-- TODO setWindowShape and stuff

-- SDL3.Surface ----------------------------------------------------------------

-- XXX no copy is made for the pixel data. Scary!!!
-- foreign import capi unsafe "SDL3/SDL.h SDL_CreateSurfaceFrom"
--   sdlCreateSurfaceFrom
--     :: CInt -> CInt -> SDLPixelFormat -> Ptr () -> CInt -> IO (Ptr SDLSurface)
-- foreign import capi unsafe "SDL3/SDL.h SDL_DestroySurface"
--   sdlDestroySurface :: Ptr SDLSurface -> IO ()

-- for FinalizerPtr
foreign import capi unsafe "SDL3/SDL.h &SDL_DestroySurface"
  sdlDestroySurface' :: FunPtr (Ptr SDLSurface -> IO ())

-- SDL3.Render -----------------------------------------------------------------

foreign import capi "SDL3/SDL.h SDL_CreateRenderer" -- XXX Safe due to window system interaction
  sdlCreateRenderer :: Ptr SDLWindow -> CString -> IO (Ptr SDLRenderer)
foreign import capi "SDL3/SDL.h SDL_DestroyRenderer" -- XXX Safe due to potential cleanup
  sdlDestroyRenderer :: Ptr SDLRenderer -> IO ()
foreign import capi unsafe "SDL3/SDL.h SDL_RenderClear"
  sdlRenderClear :: Ptr SDLRenderer -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_RenderPresent"
  sdlRenderPresent :: Ptr SDLRenderer -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_GetTextureSize"
  sdlGetTextureSize :: Ptr SDLTexture -> Ptr CFloat -> Ptr CFloat -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_RenderTexture"
  sdlRenderTexture
    :: Ptr SDLRenderer -> Ptr SDLTexture -> Ptr SDLFRect -> Ptr SDLFRect -> IO CBool
foreign import capi unsafe "SDL3/SDL.h SDL_SetRenderDrawColor"
  sdlSetRenderDrawColor
    :: Ptr SDLRenderer -> Word8 -> Word8 -> Word8 -> Word8 -> IO CBool

-- foreign import capi unsafe "SDL3/SDL.h SDL_CreateTextureFromSurface"
--   sdlCreateTextureFromSurface
--     :: Ptr SDLRenderer -> Ptr SDLSurface -> IO (Ptr SDLTexture)
foreign import capi unsafe "SDL3/SDL.h SDL_DestroyTexture"
  sdlDestroyTexture :: Ptr SDLTexture -> IO ()

-- for FinalizerPtr
foreign import capi unsafe "SDL3/SDL.h &SDL_DestroyTexture"
  sdlDestroyTexture' :: FunPtr (Ptr SDLTexture -> IO ())
