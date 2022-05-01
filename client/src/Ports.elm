port module Ports exposing
    ( FromJsMsg(..)
    , ToJsMsg(..)
    , lobbySubscribe
    , subscription
    )

import Api.Subscriptions as Subscriptions
import Effect exposing (Effect)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- PUBLIC


type ToJsMsg
    = LobbySubscribe String


type FromJsMsg
    = LobbyUpdated Subscriptions.LobbyData


lobbySubscribe : Effect msg
lobbySubscribe =
    send (LobbySubscribe Subscriptions.lobbyUpdatesDocument)


send : ToJsMsg -> Effect msg
send =
    encodeToJs >> toJs >> Effect.fromCmd


subscription : (Result Decode.Error FromJsMsg -> msg) -> Sub msg
subscription toMsg =
    let
        handleJson : Decode.Value -> Result Decode.Error FromJsMsg
        handleJson json =
            Decode.decodeValue fromJsDecoder json
    in
    fromJs (handleJson >> toMsg)



-- ENCODE / DECODE


type alias PortMsgJson =
    { kind : String
    , value : Decode.Value
    }


encodePortMsg : PortMsgJson -> Encode.Value
encodePortMsg msgJson =
    Encode.object
        [ ( "kind", Encode.string msgJson.kind )
        , ( "value", msgJson.value )
        ]


fromJsDecoder : Decoder FromJsMsg
fromJsDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen valueDecoderForKind


valueDecoderForKind : String -> Decoder FromJsMsg
valueDecoderForKind kind =
    case kind of
        "lobby-updated" ->
            Decode.map LobbyUpdated
                (Decode.field "value" Subscriptions.lobbyUpdatesDecoder)

        other ->
            Decode.fail ("unexpected port msg kind: " ++ other)


encodeToJs : ToJsMsg -> Encode.Value
encodeToJs msg =
    case msg of
        LobbySubscribe document ->
            encodePortMsg
                { kind = "lobby-subscribe"
                , value = Encode.string document
                }



-- PORTS


port toJs : Decode.Value -> Cmd msg


port fromJs : (Decode.Value -> msg) -> Sub msg
