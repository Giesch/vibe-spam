module Pages.Rooms.Slug_ exposing
    ( Model
    , Msg
    , page
    )

import Components.PageHeader as PageHeader
import Css exposing (Style)
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
    , authorSessionId : String
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
    , main_
        [ css [ Tw.h_full, Tw.grid, Tw.grid_flow_row, Tw.grid_cols_6, Tw.grid_rows_1 ] ]
        [ leftSection, rightSection ]
    ]


leftSection : Html Msg
leftSection =
    section
        [ css
            [ Tw.col_span_1
            , Tw.h_full
            , Tw.flex
            , Tw.flex_col_reverse
            , Tw.bg_green_500
            , Tw.text_white
            , Tw.p_10
            , Tw.text_lg
            , Tw.font_bold
            ]
        ]
        [ text "Room Title" ]


rightSection : Html Msg
rightSection =
    section [ css [ Tw.col_span_5, Tw.flex, Tw.flex_col_reverse ] ]
        [ viewMessage "Message 1"
        , viewMessage "Message 2"
        , viewMessage "Message 3"
        ]


viewMessage : String -> Html Msg
viewMessage message =
    div [ css [ Tw.w_full, Tw.p_6 ] ]
        [ text message ]


debug : List Style
debug =
    [ Tw.border_4, Tw.border_red_800 ]
