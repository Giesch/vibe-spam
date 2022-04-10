module Pages.Home_ exposing (Model, Msg, page)

import Api
import Components.Header as Header
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Page
import RemoteData exposing (RemoteData)
import Request
import Shared
import Shared.Session as Session exposing (Session)
import Tailwind.Utilities as Tw
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- INIT


type alias Model =
    { session : Maybe Session
    , lobby : Api.GraphqlData Api.LobbyData
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( { session = shared.session
      , lobby = RemoteData.NotAsked
      }
    , fetchLobby
    )



-- UPDATE


type Msg
    = GotLobby (Api.GraphqlData Api.LobbyData)
    | GotCreatedRoom (Api.GraphqlData Api.RoomData)
    | CreateRoom


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotLobby lobby ->
            ( { model | lobby = lobby }, Effect.none )

        GotCreatedRoom room ->
            let
                newLobby =
                    RemoteData.map2 addRoom model.lobby room
            in
            ( { model | lobby = newLobby }, Effect.none )

        CreateRoom ->
            ( model, createRoom )


addRoom : Api.LobbyData -> Api.RoomData -> Api.LobbyData
addRoom lobby room =
    { lobby | rooms = room :: lobby.rooms }



-- VIEW


view : Model -> View Msg
view model =
    { title = "home"
    , body = [ Header.view, viewSession model.session ]
    }


viewSession : Maybe Session -> Html msg
viewSession maybeSession =
    case maybeSession of
        Just session ->
            div
                [ css [ Tw.flex, Tw.flex_col ] ]
                [ div [] [ text <| Session.id session ]
                ]

        Nothing ->
            text "no session"



-- Effects


fetchLobby : Effect Msg
fetchLobby =
    Api.fetchLobby GotLobby


createRoom : Effect Msg
createRoom =
    Api.createRoom GotCreatedRoom
