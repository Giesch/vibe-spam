module Shared.Flags exposing (Flags, decoder)

import Api.LobbyData as LobbyData exposing (LobbyData)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import Shared.Session as Session exposing (Session)


type alias Flags =
    -- NOTE this needs to match the rust struct ElmFlagsJson
    { session : Maybe Session
    , lobby : LobbyData
    }


decoder : Decoder Flags
decoder =
    Decode.succeed Flags
        |> JDP.optional "session" (Decode.map Just Session.decoder) Nothing
        |> JDP.required "lobby" LobbyData.decoder
