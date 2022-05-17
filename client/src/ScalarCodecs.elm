module ScalarCodecs exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import ScalarCodecs.Uuid as Uuid
import Time
import VibeSpam.Scalar


type alias PosixTime =
    Time.Posix


type alias Uuid =
    Uuid.Uuid


codecs : VibeSpam.Scalar.Codecs Time.Posix Uuid
codecs =
    VibeSpam.Scalar.defineCodecs
        { codecUuid = Uuid.codec
        , codecPosixTime =
            { encoder = posixEncoder
            , decoder = posixDecoder
            }
        }


posixEncoder : Time.Posix -> Encode.Value
posixEncoder posix =
    posix
        |> Time.posixToMillis
        |> Encode.int


posixDecoder : Decoder Time.Posix
posixDecoder =
    Decode.map Time.millisToPosix Decode.int
