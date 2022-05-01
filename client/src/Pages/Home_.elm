module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.LobbyData exposing (LobbyData)
import Api.RoomData exposing (RoomData)
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Page
import Ports
import RemoteData
import Request
import Shared
import Shared.Session as Session exposing (Session)
import Tailwind.Utilities as Tw
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.advanced
        { init = init shared
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { session : Maybe Session
    , lobby : Api.GraphqlData LobbyData
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( { session = shared.session
      , lobby = RemoteData.Success shared.lobby
      }
    , Ports.lobbySubscribe
    )



-- UPDATE


type Msg
    = GotCreatedRoom
    | CreateRoom
    | FromJs (Result Decode.Error Ports.FromJsMsg)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotCreatedRoom ->
            ( model, Effect.none )

        CreateRoom ->
            ( model, createRoom )

        FromJs (Ok (Ports.LobbyUpdated lobbyData)) ->
            ( { model | lobby = RemoteData.Success lobbyData }
            , Effect.none
            )

        FromJs (Err _) ->
            ( model, Effect.none )



-- EFFECTS


createRoom : Effect Msg
createRoom =
    Api.createRoom (\_ -> GotCreatedRoom)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.subscription FromJs



-- VIEW


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
                [ div []
                    [ text <| "session: " ++ Session.id session
                    ]
                ]

        Nothing ->
            text "no session"


viewCreateRoomButton : Html Msg
viewCreateRoomButton =
    button
        [ Events.onClick CreateRoom ]
        [ text "Create Room" ]


viewLobby : Api.GraphqlData LobbyData -> Html msg
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
    div [] <| [ text "loading..." ]


viewRoomRow : RoomData -> Html msg
viewRoomRow room =
    div [] [ text ("room: " ++ room.title) ]
