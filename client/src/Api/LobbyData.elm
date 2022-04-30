module Api.LobbyData exposing (LobbyData, decoder)

import Api.RoomData as RoomData exposing (RoomData)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP


type alias LobbyData =
    { rooms : List RoomData
    }


decoder : Decoder LobbyData
decoder =
    Decode.succeed LobbyData
        |> JDP.required "rooms" (Decode.list RoomData.decoder)
