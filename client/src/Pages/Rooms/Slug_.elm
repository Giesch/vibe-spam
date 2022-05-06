module Pages.Rooms.Slug_ exposing
    ( Model
    , Msg
    , page
    )

import Components.PageHeader as PageHeader
import Css
import Effect exposing (Effect)
import Gen.Params.Rooms.Slug_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attrs exposing (css)
import Page
import Request
import Shared
import Tailwind.Utilities as Tw
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.advanced
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { messages : List MessageData
    }


type alias MessageData =
    { content : String
    , authoredByUs : Bool
    }


init : ( Model, Effect Msg )
init =
    ( { messages = []
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view _ =
    { title = "vibe spam - room"
    , body = layout
    }


layout : List (Html Msg)
layout =
    [ PageHeader.view
    ]
