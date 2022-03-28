module Shared.Flags exposing (Flags, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import Shared.Session as Session exposing (Session)


type alias Flags =
    -- NOTE this needs to match the rust struct ElmFlagsJson
    { session : Maybe Session
    }


decoder : Decoder Flags
decoder =
    Decode.succeed Flags
        |> JDP.optional "session" (Decode.map Just Session.decoder) Nothing
