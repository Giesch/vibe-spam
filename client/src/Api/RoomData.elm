module Api.RoomData exposing (RoomData, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP


type alias RoomData =
    { title : String
    }


decoder : Decoder RoomData
decoder =
    Decode.succeed RoomData
        |> JDP.required "title" Decode.string
