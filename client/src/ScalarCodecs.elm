module ScalarCodecs exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import ScalarCodecs.Uuid as Uuid
import VibeSpam.Scalar exposing (defaultCodecs)


type alias DateTime =
    VibeSpam.Scalar.DateTime


type alias Uuid =
    Uuid.Uuid


codecs : VibeSpam.Scalar.Codecs DateTime Uuid
codecs =
    VibeSpam.Scalar.defineCodecs
        { codecDateTime = defaultCodecs.codecDateTime
        , codecUuid = Uuid.codec
        }
