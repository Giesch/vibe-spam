module Pages.Rooms.Slug_ exposing
    ( Model
    , Msg
    , page
    )

import Css exposing (Style)
import Data.Emoji as Emoji exposing (Emoji)
import Effect exposing (Effect)
import Gen.Params.Rooms.Slug_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attrs exposing (css)
import Json.Decode as Decode
import Page
import Ports
import Request
import Shared
import Shared.Session as Session
import Tailwind.Utilities as Tw
import View exposing (View)
import Views.PageHeader as PageHeader


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { messages : List MessageData
    , roomTitle : String
    , sessionId : Maybe String
    }


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        roomTitle : String
        roomTitle =
            req.params.slug
    in
    ( { messages = fakeMessages
      , roomTitle = roomTitle
      , sessionId = Maybe.map Session.id shared.session
      }
    , Ports.chatRoomSubscribe { roomTitle = roomTitle }
    )


type alias MessageData =
    { emoji : Emoji
    , authorSessionId : String
    }


type alias MessageView =
    { content : String
    , authorColor : Style
    , alignment : Style
    }


fakeMessages : List MessageData
fakeMessages =
    -- TODO unexpose Emoji(..) after removing this
    let
        ourSessionId : String
        ourSessionId =
            "668adab3-356b-4556-9d39-00c17b8dc227"
    in
    [ { emoji = Emoji.SweatSmile
      , authorSessionId = ourSessionId
      }
    , { emoji = Emoji.Smile
      , authorSessionId = "theirSessionId"
      }
    , { emoji = Emoji.Heart
      , authorSessionId = ourSessionId
      }
    ]



-- UPDATE


type Msg
    = FromJs (Result Decode.Error Ports.FromJsMsg)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        FromJs result ->
            let
                _ =
                    Debug.log "result" result
            in
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.subscription FromJs



-- VIEW


view : Model -> View Msg
view model =
    { title = "vibespam | " ++ model.roomTitle
    , body = layout model
    }


layout : Model -> List (Html Msg)
layout model =
    [ PageHeader.view
    , main_
        [ css [ Tw.h_full, Tw.grid, Tw.grid_flow_row, Tw.grid_cols_6, Tw.grid_rows_1 ] ]
        [ leftSection model.roomTitle, rightSection model.sessionId model.messages ]
    ]


leftSection : String -> Html Msg
leftSection roomTitle =
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
        [ text roomTitle ]


rightSection : Maybe String -> List MessageData -> Html Msg
rightSection sessionId messages =
    let
        messageViews : List (Html Msg)
        messageViews =
            List.reverse <| List.map (viewMessage sessionId) messages
    in
    section [ css [ Tw.col_span_5, Tw.flex, Tw.flex_col_reverse ] ]
        (viewEmojiPanel :: messageViews)


viewMessage : Maybe String -> MessageData -> Html Msg
viewMessage sessionId messageData =
    let
        content : String
        content =
            Emoji.toString messageData.emoji

        authorStyles : List Style
        authorStyles =
            if sessionId == Just messageData.authorSessionId then
                [ Tw.bg_green_100, Tw.text_left ]

            else
                [ Tw.bg_blue_100, Tw.text_right ]

        bubbleStyles : List Style
        bubbleStyles =
            [ Tw.p_2, Tw.rounded, Tw.w_16 ] ++ authorStyles
    in
    div
        [ css [ Tw.w_full, Tw.p_6 ] ]
        [ div [ css bubbleStyles ] [ text content ] ]


viewEmojiPanel : Html Msg
viewEmojiPanel =
    let
        styles : List Style
        styles =
            [ Tw.flex
            , Tw.flex_row
            , Tw.border_t_2
            , Tw.border_green_200
            , Tw.px_4
            , Tw.py_2
            ]
    in
    div [ css styles ] <|
        List.map viewEmojiButton emojiOptions


emojiOptions : List String
emojiOptions =
    List.map Emoji.toString Emoji.all


viewEmojiButton : String -> Html Msg
viewEmojiButton emoji =
    button
        [ css [ Tw.px_2, Tw.py_1, Tw.mx_1 ] ]
        [ text emoji ]
