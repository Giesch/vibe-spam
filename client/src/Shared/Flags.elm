module Shared.Flags exposing
    ( Flags
    , decoder
    , default
    )

import Api.LobbyData as LobbyData exposing (LobbyData)
import Dict
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import Shared.Session as Session exposing (Session)
import Time
import TimeZone


type alias Flags =
    -- from the server
    -- these need to match the rust struct ElmFlagsJson
    { session : Maybe Session
    , lobby : LobbyData

    -- from the client
    , timeZone : Time.Zone
    }


default : Flags
default =
    { session = Nothing
    , lobby = { rooms = [] }
    , timeZone = defaultZone
    }


defaultZone : Time.Zone
defaultZone =
    TimeZone.america__chicago ()


decoder : Decoder Flags
decoder =
    Decode.succeed Flags
        |> JDP.optional "session" (Decode.map Just Session.decoder) Nothing
        |> JDP.required "lobby" LobbyData.decoder
        |> JDP.required "timeZone" timeZoneDecoder


timeZoneDecoder : Decoder Time.Zone
timeZoneDecoder =
    Decode.map lookupZone Decode.string


lookupZone : String -> Time.Zone
lookupZone name =
    case Dict.get name TimeZone.zones of
        Nothing ->
            defaultZone

        Just lazyZone ->
            lazyZone ()
