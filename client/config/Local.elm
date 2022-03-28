module Config exposing (..)

{-| Local API Config
This points the app at a locally running backend instance

Avoid editing the copy of this file in the .config directory,
and use the 'config:' npm scripts instead.

-}


apiTarget : String
apiTarget =
    "http://localhost:8080"
