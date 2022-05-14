port module Ports exposing
    ( ChatRoomSubscribeJson
    , FromJsMsg(..)
    , ToJsMsg(..)
    , chatRoomSubscribe
    , lobbySubscribe
    , subscription
    )

import Api.Subscriptions as Subscriptions
import Effect exposing (Effect)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDP
import Json.Encode as Encode



-- PUBLIC


type ToJsMsg
    = LobbySubscribe String
    | ChatRoomSubscribe ChatRoomSubscribeJson


type alias ChatRoomSubscribeJson =
    { roomTitle : String
    , document : String
    }


type FromJsMsg
    = LobbyUpdated Subscriptions.LobbyData
    | ChatRoomUpdated (List Subscriptions.ChatMessageData)


lobbySubscribe : Effect msg
lobbySubscribe =
    send (LobbySubscribe Subscriptions.lobbyUpdatesDocument)


chatRoomSubscribe : { roomTitle : String } -> Effect msg
chatRoomSubscribe args =
    let
        json : ChatRoomSubscribeJson
        json =
            { roomTitle = args.roomTitle
            , document = Subscriptions.chatRoomUpdatesDocument args
            }
    in
    send (ChatRoomSubscribe json)


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
    let
        decodeMsg : (data -> msg) -> Decoder data -> Decoder msg
        decodeMsg toMsg valueDecoder =
            Decode.map toMsg (Decode.field "value" valueDecoder)
    in
    case kind of
        "lobby-updated" ->
            decodeMsg LobbyUpdated Subscriptions.lobbyUpdatesDecoder

        "chat-room-updated" ->
            decodeMsg ChatRoomUpdated chatMessagesDecoder

        other ->
            Decode.fail ("unexpected port msg kind: " ++ other)


chatMessagesDecoder : Decoder (List Subscriptions.ChatMessageData)
chatMessagesDecoder =
    let
        decoderForResult : ChatRoomUpdate -> Decoder (List Subscriptions.ChatMessageData)
        decoderForResult update =
            Decode.field "result" (decoderForRoomTitle update.roomTitle)

        decoderForRoomTitle : String -> Decoder (List Subscriptions.ChatMessageData)
        decoderForRoomTitle roomTitle =
            Subscriptions.chatRoomUpdatesDecoder { roomTitle = roomTitle }
    in
    Decode.andThen decoderForResult chatRoomUpdateDecoder


type alias ChatRoomUpdate =
    { roomTitle : String
    , result : Decode.Value
    }


chatRoomUpdateDecoder : Decoder ChatRoomUpdate
chatRoomUpdateDecoder =
    Decode.succeed ChatRoomUpdate
        |> JDP.required "roomTitle" Decode.string
        |> JDP.required "result" Decode.value


encodeToJs : ToJsMsg -> Encode.Value
encodeToJs msg =
    case msg of
        LobbySubscribe document ->
            encodePortMsg
                { kind = "lobby-subscribe"
                , value = Encode.string document
                }

        ChatRoomSubscribe json ->
            encodePortMsg
                { kind = "chat-room-subscribe"
                , value =
                    Encode.object
                        [ ( "roomTitle", Encode.string json.roomTitle )
                        , ( "document", Encode.string json.document )
                        ]
                }



-- PORTS


port toJs : Decode.Value -> Cmd msg


port fromJs : (Decode.Value -> msg) -> Sub msg
