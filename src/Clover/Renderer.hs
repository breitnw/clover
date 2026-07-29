module Clover.Renderer (
  module Clover.Renderer.Error,
) where

import Clover.Renderer.Error

-- TODO do this in some sort of renderer monad

-- | Convert an STB image to an SDL surface
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
