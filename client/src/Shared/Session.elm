module Shared.Session exposing (Session, decoder, id)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import ScalarCodecs.Uuid as Uuid exposing (Uuid)


type Session
    = Session SessionJson


id : Session -> Uuid
id (Session session) =
    session.sessionId


decoder : Decoder Session
decoder =
    Decode.map Session decodeJson


type alias SessionJson =
    -- NOTE this needs to match the rust struct ElmSessionJson
    { sessionId : Uuid
    }


decodeJson : Decoder SessionJson
decodeJson =
    Decode.succeed SessionJson
        |> JDP.required "sessionId" (Decode.map Uuid.fromString Decode.string)
