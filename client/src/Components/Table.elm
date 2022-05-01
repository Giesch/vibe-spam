module Components.Table exposing
    ( Config
    , view
    )

import Api.RoomData exposing (RoomData)
import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Config =
    { rows : List RoomData
    }



-- TODO this isn't correctly responsive;
-- need to prevent horizontal overflow


view : Config -> Html msg
view _ =
    div
        [ css [ Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
        [ div
            [ css [ Bp.sm [ Tw.flex, Tw.items_center ] ] ]
            [ div
                [ css [ Bp.sm [ Tw.flex_auto ] ] ]
                [ heading "Lobby" ]
            , div
                [ css [ Tw.mt_4, Bp.sm [ Tw.mt_0, Tw.ml_16, Tw.flex_none ] ] ]
                [ addRowButton { text = "New Room" } ]
            ]
        , div
            [ css [ Tw.mt_8, Tw.flex, Tw.flex_col ] ]
            [ div
                [ css
                    [ Tw.neg_my_2
                    , Tw.neg_mx_4
                    , Tw.overflow_x_auto
                    , Bp.lg [ Tw.neg_mx_8 ]
                    , Bp.sm [ Tw.neg_mx_6 ]
                    ]
                ]
                [ div
                    [ css
                        [ Tw.inline_block
                        , Tw.min_w_full
                        , Tw.py_2
                        , Tw.align_middle
                        , Bp.lg [ Tw.px_8 ]
                        , Bp.md [ Tw.px_6 ]
                        ]
                    ]
                    [ table
                        [ css [ Tw.min_w_full, Tw.divide_y, Tw.divide_gray_300 ] ]
                        [ thead []
                            [ tr []
                                [ th
                                    [ Attr.scope "col"
                                    , css
                                        [ Tw.py_3_dot_5
                                        , Tw.pl_4
                                        , Tw.pr_3
                                        , Tw.text_left
                                        , Tw.text_sm
                                        , Tw.font_semibold
                                        , Tw.text_gray_900
                                        , Bp.md [ Tw.pl_0 ]
                                        , Bp.sm [ Tw.pl_6 ]
                                        ]
                                    ]
                                    [ text "Name" ]
                                , th
                                    [ Attr.scope "col"
                                    , css
                                        [ Tw.py_3_dot_5
                                        , Tw.px_3
                                        , Tw.text_left
                                        , Tw.text_sm
                                        , Tw.font_semibold
                                        , Tw.text_gray_900
                                        ]
                                    ]
                                    [ text "Title" ]
                                , th
                                    [ Attr.scope "col"
                                    , css
                                        [ Tw.py_3_dot_5
                                        , Tw.px_3
                                        , Tw.text_left
                                        , Tw.text_sm
                                        , Tw.font_semibold
                                        , Tw.text_gray_900
                                        ]
                                    ]
                                    [ text "Email" ]
                                , th
                                    [ Attr.scope "col"
                                    , css
                                        [ Tw.py_3_dot_5
                                        , Tw.px_3
                                        , Tw.text_left
                                        , Tw.text_sm
                                        , Tw.font_semibold
                                        , Tw.text_gray_900
                                        ]
                                    ]
                                    [ text "Role" ]
                                , th
                                    [ Attr.scope "col"
                                    , css
                                        [ Tw.relative
                                        , Tw.py_3_dot_5
                                        , Tw.pl_3
                                        , Tw.pr_4
                                        , Bp.md [ Tw.pr_0 ]
                                        , Bp.sm [ Tw.pr_6 ]
                                        ]
                                    ]
                                    -- TODO failed to fix the mobile version
                                    [ screenReaderSpan "Edit" ]
                                ]
                            ]
                        , tbody
                            [ css [ Tw.divide_y, Tw.divide_gray_200 ] ]
                            [ tr []
                                [ td
                                    [ css
                                        [ Tw.whitespace_nowrap
                                        , Tw.py_4
                                        , Tw.pl_4
                                        , Tw.pr_3
                                        , Tw.text_sm
                                        , Tw.font_medium
                                        , Tw.text_gray_900
                                        , Bp.md [ Tw.pl_0 ]
                                        , Bp.sm [ Tw.pl_6 ]
                                        ]
                                    ]
                                    [ text "Lindsay Walton" ]
                                , td
                                    [ css
                                        [ Tw.whitespace_nowrap
                                        , Tw.py_4
                                        , Tw.px_3
                                        , Tw.text_sm
                                        , Tw.text_gray_500
                                        ]
                                    ]
                                    [ text "Front-end Developer" ]
                                , td
                                    [ css
                                        [ Tw.whitespace_nowrap
                                        , Tw.py_4
                                        , Tw.px_3
                                        , Tw.text_sm
                                        , Tw.text_gray_500
                                        ]
                                    ]
                                    [ text "lindsay.walton@example.com" ]
                                , td
                                    [ css
                                        [ Tw.whitespace_nowrap
                                        , Tw.py_4
                                        , Tw.px_3
                                        , Tw.text_sm
                                        , Tw.text_gray_500
                                        ]
                                    ]
                                    [ text "Member" ]
                                , td
                                    [ css
                                        [ Tw.relative
                                        , Tw.whitespace_nowrap
                                        , Tw.py_4
                                        , Tw.pl_3
                                        , Tw.pr_4
                                        , Tw.text_right
                                        , Tw.text_sm
                                        , Tw.font_medium
                                        , Bp.md [ Tw.pr_0 ]
                                        , Bp.sm [ Tw.pr_6 ]
                                        ]
                                    ]
                                    [ a
                                        [ Attr.href "#"
                                        , css
                                            [ Tw.text_green_600
                                            , Css.hover [ Tw.text_green_900 ]
                                            ]
                                        ]
                                        [ text "Join"
                                        , screenReaderSpan ", Lindsay Walton"
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


screenReaderSpan : String -> Html msg
screenReaderSpan toRead =
    span
        [ css [ Tw.sr_only ] ]
        [ text toRead ]


heading : String -> Html msg
heading name =
    h1
        [ css [ Tw.text_xl, Tw.font_semibold, Tw.text_gray_900 ] ]
        [ text name ]


type alias AddRowButtonConfig =
    { text : String
    }


addRowButton : AddRowButtonConfig -> Html msg
addRowButton config =
    button
        [ Attr.type_ "button"
        , css
            [ Tw.inline_flex
            , Tw.items_center
            , Tw.justify_center
            , Tw.rounded_md
            , Tw.border
            , Tw.border_transparent
            , Tw.bg_green_600
            , Tw.px_4
            , Tw.py_2
            , Tw.text_sm
            , Tw.font_medium
            , Tw.text_white
            , Tw.shadow_sm
            , Css.focus
                [ Tw.outline_none
                , Tw.ring_2
                , Tw.ring_green_500
                , Tw.ring_offset_2
                ]
            , Css.hover [ Tw.bg_green_700 ]
            , Bp.sm [ Tw.w_auto ]
            ]
        ]
        [ text config.text ]
