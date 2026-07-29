{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Clover.App.Monad (
-- AppExit (..),
-- App,
-- currentWindow,
-- currentRenderer,

) where

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
