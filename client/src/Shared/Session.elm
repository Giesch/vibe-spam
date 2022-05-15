module Shared.Session exposing (Session, decoder, id)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import VibeSpam.Scalar as Scalar exposing (Uuid)


type Session
    = Session SessionJson


id : Session -> Uuid
id (Session session) =
    Scalar.Uuid session.sessionId


decoder : Decoder Session
decoder =
    Decode.map Session decodeJson


type alias SessionJson =
    -- NOTE this needs to match the rust struct ElmSessionJson
    { sessionId : String
    }


decodeJson : Decoder SessionJson
decodeJson =
    Decode.succeed SessionJson
        |> JDP.required "sessionId" Decode.string
