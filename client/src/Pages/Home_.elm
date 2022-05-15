module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.LobbyData exposing (LobbyData)
import Api.RoomData exposing (RoomData)
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Json.Decode as Decode
import Page
import Ports
import Request
import Shared
import Shared.Routes as Routes
import Shared.Session exposing (Session)
import Tailwind.Utilities as Tw
import View exposing (View)
import Views.LobbyTable as LobbyTable
import Views.PageHeader as PageHeader


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
    , lobby : Result String LobbyData
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( { session = shared.session
      , lobby = Ok shared.lobby
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
            ( { model | lobby = Ok lobbyData }
            , Effect.none
            )

        FromJs (Ok _) ->
            -- chat room update
            ( model, Effect.none )

        FromJs (Err error) ->
            ( { model | lobby = Err (Decode.errorToString error) }
            , Effect.none
            )



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
    { title = "vibespam"
    , body = layout model
    }


layout : Model -> List (Html Msg)
layout model =
    let
        mainContent : Html Msg
        mainContent =
            case model.lobby of
                Ok lobby ->
                    content lobby

                Err error ->
                    text ("Oops! Something went wrong: " ++ error)
    in
    [ PageHeader.view
    , main_ [ css [ Tw.flex_grow ] ]
        [ mainContent ]
    ]


content : LobbyData -> Html Msg
content lobby =
    let
        toRoomRow : RoomData -> LobbyTable.RoomRow
        toRoomRow room =
            { title = room.title
            , lastActivity = "2022 04 01"
            , joinLink = Routes.rooms { slug = room.title }
            }
    in
    div [ css [ Tw.px_32, Tw.py_16 ] ]
        [ div [ css [ Tw.flex, Tw.flex_col, Tw.space_y_2 ] ]
            [ LobbyTable.view
                { rows = List.map toRoomRow lobby.rooms
                , onNewRoom = CreateRoom
                }
            ]
        ]
