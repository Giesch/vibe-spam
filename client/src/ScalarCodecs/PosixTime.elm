module ScalarCodecs.PosixTime exposing
    ( codec
    , decoder
    )

import Graphql.Codec exposing (Codec)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time


codec : Codec Time.Posix
codec =
    { encoder = encode
    , decoder = decoder
    }


encode : Time.Posix -> Encode.Value
encode posix =
    posix
        |> Time.posixToMillis
        |> Encode.int


decoder : Decoder Time.Posix
decoder =
    Decode.map Time.millisToPosix Decode.int
