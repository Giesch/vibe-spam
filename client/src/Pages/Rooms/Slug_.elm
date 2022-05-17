module Pages.Rooms.Slug_ exposing
    ( MessageData
    , Model
    , Msg
    , page
    )

import Api
import Api.Subscriptions exposing (ChatMessageData)
import Css exposing (Style)
import Data.Emoji as Emoji exposing (Emoji)
import Effect exposing (Effect)
import Gen.Params.Rooms.Slug_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Page
import Ports
import Request
import ScalarCodecs.Uuid as Uuid exposing (Uuid)
import Shared
import Shared.Session as Session
import Tailwind.Utilities as Tw
import VibeSpam.InputObject as InputObject
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
    , sessionId : Maybe Uuid
    }


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        roomTitle : String
        roomTitle =
            req.params.slug
    in
    ( { messages = []
      , roomTitle = roomTitle
      , sessionId = Maybe.map Session.id shared.session
      }
    , Ports.chatRoomSubscribe { roomTitle = roomTitle }
    )


type alias MessageData =
    { emoji : Emoji
    , authorSessionId : Uuid
    }



-- UPDATE


type Msg
    = FromJs (Result Decode.Error Ports.FromJsMsg)
    | CreatedMessage
    | EmojiClicked Emoji


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        FromJs (Ok (Ports.ChatRoomUpdated newMessages)) ->
            let
                toUiMessage : ChatMessageData -> MessageData
                toUiMessage { emoji, authorSessionId } =
                    { emoji = Emoji.fromGraphql emoji
                    , authorSessionId = authorSessionId
                    }

                updatedMessages : List MessageData
                updatedMessages =
                    List.map toUiMessage newMessages ++ model.messages
            in
            ( { model | messages = updatedMessages }
            , Effect.none
            )

        FromJs (Ok _) ->
            -- lobby subscription message
            ( model, Effect.none )

        FromJs (Err _) ->
            ( model, Effect.none )

        CreatedMessage ->
            -- NOTE relying on the subscription for this
            ( model, Effect.none )

        EmojiClicked emoji ->
            ( model, createMessage model emoji )



-- Effects


createMessage : Model -> Emoji -> Effect Msg
createMessage { roomTitle, sessionId } emoji =
    case sessionId of
        Nothing ->
            Effect.none

        Just authorSessionId ->
            let
                newMessage : InputObject.NewMessage
                newMessage =
                    { emoji = Emoji.toGraphql emoji
                    , authorSessionId = authorSessionId
                    , roomTitle = roomTitle
                    }
            in
            Api.createMessage (\_ -> CreatedMessage) { newMessage = newMessage }



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
        [ leftSection model.roomTitle
        , rightSection model
        ]
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


rightSection : Model -> Html Msg
rightSection { sessionId, messages } =
    let
        messageViews : List (Html Msg)
        messageViews =
            List.map (viewMessage sessionId) messages
    in
    section [ css [ Tw.col_span_5, Tw.flex, Tw.flex_col_reverse ] ]
        (viewEmojiPanel :: messageViews)


viewMessage : Maybe Uuid -> MessageData -> Html Msg
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
    -- TODO don't display this if no session id
    -- show some kind of error
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
        List.map viewEmojiButton Emoji.all


viewEmojiButton : Emoji -> Html Msg
viewEmojiButton emoji =
    button
        [ Events.onClick (EmojiClicked emoji)
        , css [ Tw.px_2, Tw.py_1, Tw.mx_1 ]
        ]
        [ text <| Emoji.toString emoji ]
