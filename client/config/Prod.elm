module Config exposing (..)

{-| Prod API Config
This points the app at the prod backend

Avoid editing the copy of this file in the .config directory,
and use the 'config:' npm scripts instead.

-}


apiTarget : String
apiTarget =
    "https://vibe-spam.fly.dev"
