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
        -- TODO test that this is present, at least manually
        -- preferrably with an automated test on the rust side
        |> JDP.required "lobby" LobbyData.decoder
