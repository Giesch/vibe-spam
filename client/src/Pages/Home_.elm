module Pages.Home_ exposing (Model, Msg, page)

import Components.Header as Header
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Page
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
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { session : Maybe Session
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( { session = shared.session
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



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
