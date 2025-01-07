This file was generated by `cargo-cabal`, its goal is to define few hooks to
call `cargo` on the fly and link correctly the generated library.

While it's an acceptable hack as this project is currently a prototype, this
should be removed before `cargo-cabal` stable release.

> import Data.Maybe
> import qualified Distribution.PackageDescription as PD
> import Distribution.Simple
>   ( Args,
>     UserHooks (confHook, preConf),
>     defaultMainWithHooks,
>     simpleUserHooks,
>   )
> import Distribution.Simple.LocalBuildInfo
>   ( LocalBuildInfo (localPkgDescr),
>   )
> import Distribution.Simple.Setup
>   ( BuildFlags (buildVerbosity),
>     ConfigFlags (configVerbosity),
>     fromFlag,
>   )
> import Distribution.Simple.UserHooks
>   ( UserHooks (buildHook, confHook),
>   )
> import Distribution.Simple.Utils (rawSystemExit)
> import System.Directory (getCurrentDirectory)
>
> main :: IO ()
> main =
>   defaultMainWithHooks
>     simpleUserHooks
>       { confHook = rustConfHook
> --    , buildHook = rustBuildHook
>       }

This hook could be remove if at some point, likely if this issue is resolved
https://github.com/haskell/cabal/issues/2641

> rustConfHook ::
>   (PD.GenericPackageDescription, PD.HookedBuildInfo) ->
>   ConfigFlags ->
>   IO LocalBuildInfo
> rustConfHook (description, buildInfo) flags = do
>   localBuildInfo <- confHook simpleUserHooks (description, buildInfo) flags
>   let packageDescription = localPkgDescr localBuildInfo
>       library = fromJust $ PD.library packageDescription
>       libraryBuildInfo = PD.libBuildInfo library
>   dir <- getCurrentDirectory
>   return localBuildInfo
>     { localPkgDescr = packageDescription
>       { PD.library = Just $ library
>         { PD.libBuildInfo = libraryBuildInfo
>           { PD.extraLibDirs = (dir ++ "/target/release") :
>                               (dir ++ "/target/debug") :
>             PD.extraLibDirs libraryBuildInfo
>     } } } }

It would be nice to remove this hook too some point, e.g., if this RFC is merged
in Cabal https://github.com/haskell/cabal/issues/7906

% rustBuildHook ::
%   PD.PackageDescription ->
%   LocalBuildInfo ->
%   UserHooks ->
%   BuildFlags ->
%   IO ()
% rustBuildHook description localBuildInfo hooks flags = do
%   putStrLn "******************************************************************"
%   putStrLn "Call `cargo build --release` to build a dependency written in Rust"
%   -- FIXME: add `--target $TARGET` flag to support cross-compiling to $TARGET
%   rawSystemExit (fromFlag $ buildVerbosity flags) "cargo" ["build","--release"]
%   putStrLn "... `rustc` compilation seems to succeed 🦀! Back to Cabal build:"
%   putStrLn "******************************************************************"
%   putStrLn "Back to Cabal build"
%   buildHook simpleUserHooks description localBuildInfo hooks flags

This handy automation (particularly useful when you want to quickly prototype
without having to spawn manually `cargo` commands) is disabled by default.
Feel free to re-enable it while debugging your library, but I discourage you
strongly to publish anything on Hackage that contains this hook!
