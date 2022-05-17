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
            Decode.decodeValue Flags.decoder flagsJson
                |> Result.withDefault Flags.default
    in
    ( { session = flags.session
      , lobby = flags.lobby
      , timeZone = flags.timeZone
      }
    , Cmd.none
    )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ model =
    ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


googleOauthPath : String
googleOauthPath =
    "/api/auth/google"
