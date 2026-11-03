{-# LANGUAGE FlexibleInstances #-}

{- |
Module      : Effectful.MusicPlayer.Blocking.Handler.MPD.Error
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable

Higher-level errors for MPD
-}
module Effectful.MusicPlayer.Blocking.Handler.MPD.Error (
  MPDClientError (..),
  MPDServerError (..),
  Annotated (..),
  mpdRecoverError,
) where

import Foreign (Ptr)

import Data.Text qualified as T
import Effectful
import Effectful.Exception

import Foreign.Lib.MPD qualified as F
import Foreign.Util

-- NOTE Argument and State are technically recoverable in libmpdclient, but I'm
-- treating them as fatal because they should never happen.

-- | Annotate a value with some text metadata.
data Annotated a = Ann T.Text a
  deriving (Show)

-- | A problem arose with the client's connection to the server; MPD needs to restart.
data MPDClientError
  = -- | Out of memory
    COutOfMemory
  | -- | A function was called with an unrecognized or invalid argument
    CArgument
  | -- | A function was called which is not available in the current state of libmpdclient
    CState
  | -- | Timeout trying to talk to MPD
    CTimeout
  | -- | System error
    CSystem
  | -- | Unknown host
    CResolver
  | -- | Malformed response recieved from MPD
    CMalformed
  | -- | Connection closed by MPD
    CClosed
  deriving (Show)

-- TODO if client errors are not TRULY fatal, update the style guide accordingly
-- I think a better framing would be:
-- > exception if it is unrecoverable within the monad, should only be recovered in IO/IOE
-- > error if it is recoverable within the monad

-- A client error is an exception because it is fatal under the MPD connection
-- A server error is not an exception because it can be recovered from under the MPD connection
instance Exception (Annotated MPDClientError)

-- TODO I believe server errors can and should be generic across all handlers
-- so that the effect user can deal with them as desired

-- | The server returned an ACK error code; generally expected and MPD can recover.
--
-- Unfortunately there are no docs for what these mean :(
data MPDServerError
  = SUnknown
  | SNotList
  | SArg
  | SPassword
  | SPermission
  | SUnknownCmd
  | SNoExist
  | SPlaylistMax
  | SSystem
  | SPlaylistLoad
  | SUpdateAlready
  | SPlayerSync
  | SExist
  deriving (Show)

-- | Get the current MPD error and attempt to recover the MPD connection.
--
-- Returns the error recovered from, or Nothing if there was no error. If
-- the error is fatal to the MPD connection, throws an Exception.
--
-- NOTE not idempotent; will return Success on the second call if called twice
-- in a row.
-- TODO might be better to just throw an error to signify this ^
mpdRecoverError
  :: IOE :> es
  => Ptr F.MPDConnection
  -> Eff es (Maybe (Annotated MPDServerError))
mpdRecoverError conn = do
  err <- liftIO $ F.mpdConnectionGetError conn
  case err of
    F.MPD_ERROR_SUCCESS -> return Nothing
    _ -> do
      errMsg <- liftIO $ peekCString =<< F.mpdConnectionGetErrorMessage conn
      case err of
        F.MPD_ERROR_ARGUMENT -> throwIO (Ann errMsg CArgument)
        F.MPD_ERROR_STATE -> throwIO (Ann errMsg CState)
        F.MPD_ERROR_TIMEOUT -> throwIO (Ann errMsg CTimeout)
        F.MPD_ERROR_SYSTEM -> throwIO (Ann errMsg CSystem)
        F.MPD_ERROR_RESOLVER -> throwIO (Ann errMsg CResolver)
        F.MPD_ERROR_MALFORMED -> throwIO (Ann errMsg CMalformed)
        F.MPD_ERROR_CLOSED -> throwIO (Ann errMsg CClosed)
        F.MPD_ERROR_SERVER -> do
          serverErr <- liftIO $ F.mpdConnectionGetServerError conn
          serverVariant <- case serverErr of
            F.MPD_SERVER_ERROR_NOT_LIST -> return SNotList
            F.MPD_SERVER_ERROR_ARG -> return SArg
            F.MPD_SERVER_ERROR_PASSWORD -> return SPassword
            F.MPD_SERVER_ERROR_PERMISSION -> return SPermission
            F.MPD_SERVER_ERROR_UNKNOWN_CMD -> return SUnknownCmd
            F.MPD_SERVER_ERROR_NO_EXIST -> return SNoExist
            F.MPD_SERVER_ERROR_PLAYLIST_MAX -> return SPlaylistMax
            F.MPD_SERVER_ERROR_SYSTEM -> return SSystem
            F.MPD_SERVER_ERROR_PLAYLIST_LOAD -> return SPlaylistLoad
            F.MPD_SERVER_ERROR_UPDATE_ALREADY -> return SUpdateAlready
            F.MPD_SERVER_ERROR_PLAYER_SYNC -> return SPlayerSync
            F.MPD_SERVER_ERROR_EXIST -> return SExist
            _ -> return SUnknown -- Should this be the catch-all, or just for UNKNOWN?

          -- Clear is always successful for server errors, which we know we
          -- have here. It is also successful for client errors Argument and
          -- State, but I treat these errors as unrecoverable.
          _ <- liftIO $ F.mpdConnectionClearError conn
          return $ Just (Ann errMsg serverVariant)

        -- Unlike server errors with the wrong code, client errors with the
        -- wrong code are truly unreachable unless we get out-of-sync with
        -- libmpdclient. So, it's OK to call 'error'
        -- TODO if this is the desired behavior, document the circumstance where
        -- 'error' is OK in the style guide
        _ -> error $ "UNREACHABLE: unexpected client error code " <> show err
