module Api.RoomData exposing (RoomData, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import ScalarCodecs.Uuid as Uuid exposing (Uuid)


type alias RoomData =
    { id : Uuid
    , title : String
    }


decoder : Decoder RoomData
decoder =
    Decode.succeed RoomData
        |> JDP.required "id" Uuid.decoder
        |> JDP.required "title" Decode.string
