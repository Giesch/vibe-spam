module Api.RoomData exposing (RoomData, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import ScalarCodecs.PosixTime as PosixTime
import ScalarCodecs.Uuid as Uuid exposing (Uuid)
import Time


type alias RoomData =
    { id : Uuid
    , title : String
    , updatedAt : Time.Posix
    }


decoder : Decoder RoomData
decoder =
    Decode.succeed RoomData
        |> JDP.required "id" Uuid.decoder
        |> JDP.required "title" Decode.string
        |> JDP.required "updatedAt" PosixTime.decoder
