# Code style for clover modules

Clover code should be formatted by the `fourmolu` formatter, using the provided `fourmolu.yaml`.

## Module header
There are several considerations when creating a header for a new module:

### Haddock header
Each module should have a Haddock header, such as:

```haskell
{- |
Module      : Effectful.Backend
Copyright   : (c) Nick Breitling 2026
License     : GPL v3 (see LICENSE)
Maintainer  : Nick Breitling <breitling.nw@gmail.com>
Stability   : unstable
-}
```

### Exports
Exported identifiers should always be specified manually.

```haskell
module Effectful.Backend.Data (
  SongID,
  Song (..),
  Command,
) where
```

### Imports
Imports should be divided into three sections, in the below order, each separated by a newline:

1. Imports from `base`. All imported identifiers should be listed explicitly.
2. Imports from Hackage libraries (and libraries from other remote repositories). It is not necessary to list imported identifiers. All libraries except for `effectful` must be imported with a qualification.
2. Imports from other modules in this project. These do not need a qualification.

For example:

```haskell
import Control.Applicative ((<|>))
import Data.Map ((!?))
import Data.String (fromString)

import Codec.Image.STB qualified as STB
import Data.ByteString qualified as BS
import Data.Text qualified as T
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Error.Dynamic
import Effectful.Log qualified as Log
import Effectful.Network.MPD qualified as MPD

import Effectful.Backend.Data
import Effectful.Backend.Effect
import Util
```

> _Rationale..._
> - Identifiers from `base` are listed explicitly because these modules often export a lot of identifiers, many of which go unused and clutter up the namespace.
> - Libraries are qualified for ease of seeing what comes from where. `effectful` is not qualified simply because it is so ubiquitous throughout the code.
> - Local modules are unqualified with implicit imports because the project is quite small, so it's easy enough to tell what's internal already :-)

## Effects
All effects and effect handlers are housed in the `src/Effectful` directory, as opposed to the `src/Clover` directory. This is in keeping with most other libraries that supply `effectful`-flavored effects, such as `log-effectful`. 

The module structure differs depending on whether the effect is statically or dynamically dispatched. 

### Dynamically-dispatched effects
Dynamic effects should be defined in the following modules.

- `Effectful.<effect>.Effect`: Exports the effect, as well as top level helper functions that execute effect operations using `send`. Required.
- `Effectful.<effect>.Handler.<handler>`: Exports the handler(s) for the effect. Required (at least one).
- `Effectful.<effect>.Types`: Exports types specific to the effect (for example, the `Song` and `Command` types associated with the `Backend` effect). Optional.
- `Effectful.<effect>.<helper>`: Exports actions derived from the effect's primitive actions. Optional (zero or more).
- `Effectful.<effect>`: Re-exports `Effect` module, `Types` module (if it exists), and all helper modules. Does not re-export any handler modules. Required.

### Statically-dispatched effects
Static effects should follow the same format as dynamically-dispatched ones, with some small changes: 

- There are no `Handler` modules. Instead, handler logic goes directly in `Effectful.<effect>.Effect`.
- If no `Types` module or helper modules are necessary, the `src/Effectful/<effect>` directory may be elided entirely. Instead of being re-exported, the effect should be defined directly in `Effectful.<effect>`.

