module Pages.Home_ exposing (Model, Msg, page)

import Api
import Css.Transitions exposing (offset)
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
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



-- EFFECTS


fetchLobby : Effect Msg
fetchLobby =
    Api.fetchLobby GotLobby


createRoom : Effect Msg
createRoom =
    Api.createRoom GotCreatedRoom


view : Model -> View Msg
view model =
    { title = "home"
    , body =
        [ viewSession model.session
        , viewCreateRoomButton
        , viewLobby model.lobby
        ]
    }


viewSession : Maybe Session -> Html msg
viewSession maybeSession =
    case maybeSession of
        Just session ->
            div
                [ css [ Tw.flex, Tw.flex_col ] ]
                [ div [] [ text <| "session: " ++ Session.id session ]
                ]

        Nothing ->
            text "no session"


viewCreateRoomButton : Html Msg
viewCreateRoomButton =
    button
        [ Events.onClick CreateRoom ]
        [ text "Create Room" ]


viewLobby : Api.GraphqlData Api.LobbyData -> Html msg
viewLobby data =
    case data of
        RemoteData.NotAsked ->
            viewLobbyLoading

        RemoteData.Loading ->
            viewLobbyLoading

        RemoteData.Failure _ ->
            text "oops"

        RemoteData.Success lobby ->
            if List.isEmpty lobby.rooms then
                div [] [ text "empty lobby" ]

            else
                div [] (List.map viewRoomRow lobby.rooms)


viewLobbyLoading : Html msg
viewLobbyLoading =
    text "loading..."


viewRoomRow : Api.RoomData -> Html msg
viewRoomRow room =
    div []
        [ text ("room: " ++ room.title)
        ]
