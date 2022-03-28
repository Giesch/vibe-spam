module Shared exposing
    ( Model
    , Msg
    , googleOauthPath
    , init
    , subscriptions
    , update
    )

import Json.Decode as Decode
import Request exposing (Request)
import Shared.Flags
import Shared.Session as Session exposing (Session)


type alias Model =
    -- NOTE for now, this matches Flags
    { session : Maybe Session }


type Msg
    = NoOp


init : Request -> Decode.Value -> ( Model, Cmd Msg )
init _ flagsJson =
    let
        flags : Model
        flags =
            Decode.decodeValue Shared.Flags.decoder flagsJson
                |> Result.withDefault default
    in
    ( flags, Cmd.none )


default : Model
default =
    { session = Nothing
    }


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


googleOauthPath : String
googleOauthPath =
    "/api/auth/google"
