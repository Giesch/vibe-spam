module Api.RoomData exposing (RoomData, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import VibeSpam.Scalar as Scalar exposing (Uuid)


type alias RoomData =
    { id : Uuid
    , title : String
    }


decoder : Decoder RoomData
decoder =
    Decode.succeed RoomData
        |> JDP.required "id" uuidDecoder
        |> JDP.required "title" Decode.string


uuidDecoder : Decoder Uuid
uuidDecoder =
    Scalar.defaultCodecs.codecUuid.decoder
