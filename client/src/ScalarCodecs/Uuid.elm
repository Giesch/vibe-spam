module ScalarCodecs.Uuid exposing
    ( Uuid
    , codec
    , decoder
    , encode
    )

import Graphql.Codec exposing (Codec)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Uuid
    = Uuid String


codec : Codec Uuid
codec =
    { encoder = encode
    , decoder = decoder
    }


decoder : Decoder Uuid
decoder =
    Decode.string |> Decode.map Uuid


encode : Uuid -> Encode.Value
encode (Uuid raw) =
    Encode.string raw
