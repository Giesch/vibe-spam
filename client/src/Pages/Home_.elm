module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.LobbyData exposing (LobbyData)
import Api.RoomData exposing (RoomData)
import Components.Table as Table
import Css
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attrs exposing (css)
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
    { title = "vibe spam"
    , body = layout model
    }


layout : Model -> List (Html Msg)
layout model =
    [ pageHeader
    , main_ [ css [ Tw.flex_grow ] ]
        [ case model.lobby of
            RemoteData.Success lobby ->
                content lobby

            _ ->
                Debug.todo "loading/failed lobby"
        ]
    ]


content : LobbyData -> Html msg
content lobby =
    div [ css [ Tw.px_32, Tw.py_16 ] ]
        [ div [ css [ Tw.flex, Tw.flex_col, Tw.space_y_2 ] ]
            [ Table.view { rows = lobby.rooms } ]
        ]


pageHeader : Html msg
pageHeader =
    let
        headerStyles : List Css.Style
        headerStyles =
            [ Tw.bg_green_500
            , Tw.text_white
            , Tw.p_6
            , Tw.flex
            , Tw.items_end
            , Tw.space_x_10
            ]
    in
    header [ css headerStyles ]
        [ div [ css [ Tw.text_2xl, Tw.font_bold, Tw.pr_12 ] ]
            [ text "vibespam" ]
        , tabLink { name = "lobby", href = "/" }
        ]


tabLink : { name : String, href : String } -> Html msg
tabLink { name, href } =
    a [ css [ Tw.text_lg ], Attrs.href href ]
        [ text name ]


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
