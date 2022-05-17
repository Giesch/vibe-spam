module Shared exposing
    ( Model
    , Msg
    , googleOauthPath
    , init
    , subscriptions
    , update
    )

import Api.LobbyData exposing (LobbyData)
import Json.Decode as Decode
import Request exposing (Request)
import Shared.Flags as Flags exposing (Flags)
import Shared.Session exposing (Session)
import Task
import Time


type alias Model =
    { session : Maybe Session
    , lobby : LobbyData
    , timeZone : Time.Zone
    }


type Msg
    = None


init : Request -> Decode.Value -> ( Model, Cmd Msg )
init _ flagsJson =
    let
        flags : Flags
        flags =
            Decode.decodeValue
                (debug "flags decoder" Flags.decoder)
                flagsJson
                |> Result.withDefault Flags.default
    in
    ( { session = flags.session
      , lobby = flags.lobby
      , timeZone = flags.timeZone
      }
    , Cmd.none
    )


debug : String -> Decode.Decoder a -> Decode.Decoder a
debug message d =
    Decode.value
        |> Decode.andThen (debugHelper message d)


debugHelper : String -> Decode.Decoder a -> Decode.Value -> Decode.Decoder a
debugHelper message d value =
    let
        _ =
            Debug.log message (Decode.decodeValue d value)
    in
    d


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ model =
    ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


googleOauthPath : String
googleOauthPath =
    "/api/auth/google"
