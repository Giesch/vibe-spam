module ScalarCodecs exposing (..)

{-| Custom Scalar Codecs

This module is used by the generated code, and has to obey an expected structure.
<https://github.com/dillonkearns/elm-graphql/blob/master/examples/src/Example07CustomCodecs.elm>

-}

import ScalarCodecs.PosixTime as PosixTime
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
        { codecPosixTime = PosixTime.codec
        , codecUuid = Uuid.codec
        }
