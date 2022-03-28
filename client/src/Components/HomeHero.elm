module Components.HomeHero exposing (view)

import Components.NumberInput as NumberInput
import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
import Shared
import Svg.Styled as Svg exposing (path, svg)
import Svg.Styled.Attributes as SvgAttr
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Config msg =
    { onSubmit : msg
    , left : NumberInput.Config msg
    , right : NumberInput.Config msg
    }


markSrc : String
markSrc =
    "https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg"


loginLink : Html msg
loginLink =
    span [ css [ Tw.inline_flex, Tw.rounded_md, Tw.shadow ] ]
        [ a
            [ Attr.href Shared.googleOauthPath
            , css
                [ Tw.inline_flex
                , Tw.items_center
                , Tw.px_4
                , Tw.py_2
                , Tw.border
                , Tw.border_transparent
                , Tw.text_base
                , Tw.font_medium
                , Tw.rounded_md
                , Tw.text_indigo_600
                , Tw.bg_white
                , Css.hover [ Tw.bg_gray_50 ]
                ]
            ]
            [ text "Log in" ]
        ]


view : Config msg -> Html msg
view config =
    div
        [ css [ Tw.relative, Tw.bg_gray_50, Tw.overflow_hidden ] ]
        [ div
            [ css
                [ Tw.hidden
                , Bp.sm [ Tw.block, Tw.absolute, Tw.inset_y_0, Tw.h_full, Tw.w_full ]
                ]
            , Attr.attribute "aria-hidden" "true"
            ]
            [ div
                [ css
                    [ Tw.relative
                    , Tw.h_full
                    , Tw.max_w_7xl
                    , Tw.mx_auto
                    ]
                ]
                [ svg
                    [ SvgAttr.css
                        [ Tw.absolute
                        , Tw.right_full
                        , Tw.transform
                        , Tw.translate_y_1over4
                        , Tw.translate_x_1over4
                        , Bp.lg [ Tw.translate_x_1over2 ]
                        ]
                    , SvgAttr.width "404"
                    , SvgAttr.height "784"
                    , SvgAttr.fill "none"
                    , SvgAttr.viewBox "0 0 404 784"
                    ]
                    [ Svg.defs []
                        [ Svg.pattern
                            [ SvgAttr.id "f210dbf6-a58d-4871-961e-36d5016a0f49"
                            , SvgAttr.x "0"
                            , SvgAttr.y "0"
                            , SvgAttr.width "20"
                            , SvgAttr.height "20"
                            , SvgAttr.patternUnits "userSpaceOnUse"
                            ]
                            [ Svg.rect
                                [ SvgAttr.x "0"
                                , SvgAttr.y "0"
                                , SvgAttr.width "4"
                                , SvgAttr.height "4"
                                , SvgAttr.css
                                    [ Tw.text_gray_200
                                    ]
                                , SvgAttr.fill "currentColor"
                                ]
                                []
                            ]
                        ]
                    , Svg.rect
                        [ SvgAttr.width "404"
                        , SvgAttr.height "784"
                        , SvgAttr.fill "url(#f210dbf6-a58d-4871-961e-36d5016a0f49)"
                        ]
                        []
                    ]
                , svg
                    [ SvgAttr.css
                        [ Tw.absolute
                        , Tw.left_full
                        , Tw.transform
                        , Tw.neg_translate_y_3over4
                        , Tw.neg_translate_x_1over4
                        , Bp.lg [ Tw.neg_translate_x_1over2 ]
                        , Bp.md [ Tw.neg_translate_y_1over2 ]
                        ]
                    , SvgAttr.width "404"
                    , SvgAttr.height "784"
                    , SvgAttr.fill "none"
                    , SvgAttr.viewBox "0 0 404 784"
                    ]
                    [ Svg.defs []
                        [ Svg.pattern
                            [ SvgAttr.id "5d0dd344-b041-4d26-bec4-8d33ea57ec9b"
                            , SvgAttr.x "0"
                            , SvgAttr.y "0"
                            , SvgAttr.width "20"
                            , SvgAttr.height "20"
                            , SvgAttr.patternUnits "userSpaceOnUse"
                            ]
                            [ Svg.rect
                                [ SvgAttr.x "0"
                                , SvgAttr.y "0"
                                , SvgAttr.width "4"
                                , SvgAttr.height "4"
                                , SvgAttr.css
                                    [ Tw.text_gray_200
                                    ]
                                , SvgAttr.fill "currentColor"
                                ]
                                []
                            ]
                        ]
                    , Svg.rect
                        [ SvgAttr.width "404"
                        , SvgAttr.height "784"
                        , SvgAttr.fill "url(#5d0dd344-b041-4d26-bec4-8d33ea57ec9b)"
                        ]
                        []
                    ]
                ]
            ]
        , div
            [ css
                [ Tw.relative
                , Tw.pt_6
                , Tw.pb_16
                , Bp.sm [ Tw.pb_24 ]
                ]
            ]
            [ div []
                [ div
                    [ css
                        [ Tw.max_w_7xl
                        , Tw.mx_auto
                        , Tw.px_4
                        , Bp.sm [ Tw.px_6 ]
                        ]
                    ]
                    [ nav
                        [ css
                            [ Tw.relative
                            , Tw.flex
                            , Tw.items_center
                            , Tw.justify_between
                            , Bp.md [ Tw.justify_center ]
                            , Bp.sm [ Tw.h_10 ]
                            ]
                        , Attr.attribute "aria-label" "Global"
                        ]
                        [ div
                            [ css
                                [ Tw.flex
                                , Tw.items_center
                                , Tw.flex_1
                                , Bp.md [ Tw.absolute, Tw.inset_y_0, Tw.left_0 ]
                                ]
                            ]
                            [ div
                                [ css
                                    [ Tw.flex
                                    , Tw.items_center
                                    , Tw.justify_between
                                    , Tw.w_full
                                    , Bp.md [ Tw.w_auto ]
                                    ]
                                ]
                                [ a [ Attr.href "#" ]
                                    [ span [ css [ Tw.sr_only ] ]
                                        [ text "Workflow" ]
                                    , img
                                        [ css [ Tw.h_8, Tw.w_auto, Bp.sm [ Tw.h_10 ] ]
                                        , Attr.src markSrc
                                        , Attr.alt ""
                                        ]
                                        []
                                    ]
                                , div
                                    [ css
                                        [ Tw.neg_mr_2
                                        , Tw.flex
                                        , Tw.items_center
                                        , Bp.md [ Tw.hidden ]
                                        ]
                                    ]
                                    [ button
                                        [ Attr.type_ "button"
                                        , css
                                            [ Tw.bg_gray_50
                                            , Tw.rounded_md
                                            , Tw.p_2
                                            , Tw.inline_flex
                                            , Tw.items_center
                                            , Tw.justify_center
                                            , Tw.text_gray_400
                                            , Css.focus
                                                [ Tw.outline_none
                                                , Tw.ring_2
                                                , Tw.ring_inset
                                                , Tw.ring_indigo_500
                                                ]
                                            , Css.hover [ Tw.text_gray_500, Tw.bg_gray_100 ]
                                            ]
                                        , Attr.attribute "aria-expanded" "false"
                                        ]
                                        [ span [ css [ Tw.sr_only ] ]
                                            [ text "Open main menu" ]
                                        , {- Heroicon name: outline/menu -}
                                          svg
                                            [ SvgAttr.css [ Tw.h_6, Tw.w_6 ]
                                            , SvgAttr.fill "none"
                                            , SvgAttr.viewBox "0 0 24 24"
                                            , SvgAttr.stroke "currentColor"
                                            , Attr.attribute "aria-hidden" "true"
                                            ]
                                            [ path
                                                [ SvgAttr.strokeLinecap "round"
                                                , SvgAttr.strokeLinejoin "round"
                                                , SvgAttr.strokeWidth "2"
                                                , SvgAttr.d "M4 6h16M4 12h16M4 18h16"
                                                ]
                                                []
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        , div
                            [ css
                                [ Tw.hidden
                                , Bp.md [ Tw.flex, Tw.space_x_10 ]
                                ]
                            ]
                            [ a
                                [ Attr.href "#"
                                , css
                                    [ Tw.font_medium
                                    , Tw.text_gray_500
                                    , Css.hover [ Tw.text_gray_900 ]
                                    ]
                                ]
                                [ text "Product" ]
                            , a
                                [ Attr.href "#"
                                , css
                                    [ Tw.font_medium
                                    , Tw.text_gray_500
                                    , Css.hover [ Tw.text_gray_900 ]
                                    ]
                                ]
                                [ text "Features" ]
                            , a
                                [ Attr.href "#"
                                , css
                                    [ Tw.font_medium
                                    , Tw.text_gray_500
                                    , Css.hover [ Tw.text_gray_900 ]
                                    ]
                                ]
                                [ text "Marketplace" ]
                            , a
                                [ Attr.href "#"
                                , css
                                    [ Tw.font_medium
                                    , Tw.text_gray_500
                                    , Css.hover [ Tw.text_gray_900 ]
                                    ]
                                ]
                                [ text "Company" ]
                            ]
                        , div
                            [ css
                                [ Tw.hidden
                                , Bp.md
                                    [ Tw.absolute
                                    , Tw.flex
                                    , Tw.items_center
                                    , Tw.justify_end
                                    , Tw.inset_y_0
                                    , Tw.right_0
                                    ]
                                ]
                            ]
                            [ loginLink ]
                        ]
                    ]
                ]
            , main_
                [ css
                    [ Tw.mt_16
                    , Tw.mx_auto
                    , Tw.max_w_7xl
                    , Tw.px_4
                    , Bp.sm [ Tw.mt_24 ]
                    ]
                ]
                [ div [ css [ Tw.text_center ] ]
                    [ h1
                        [ css
                            [ Tw.text_4xl
                            , Tw.tracking_tight
                            , Tw.font_extrabold
                            , Tw.text_gray_900
                            , Bp.md [ Tw.text_6xl ]
                            , Bp.sm [ Tw.text_5xl ]
                            ]
                        ]
                        [ span
                            [ css
                                [ Tw.block
                                , Bp.xl [ Tw.inline ]
                                ]
                            ]
                            [ text "Data to enrich your" ]
                        , span
                            [ css
                                [ Tw.block
                                , Tw.text_indigo_600
                                , Bp.xl [ Tw.inline ]
                                ]
                            ]
                            [ text "online business" ]
                        ]
                    , p
                        [ css
                            [ Tw.mt_3
                            , Tw.max_w_md
                            , Tw.mx_auto
                            , Tw.text_base
                            , Tw.text_gray_500
                            , Bp.md [ Tw.mt_5, Tw.text_xl, Tw.max_w_3xl ]
                            , Bp.sm [ Tw.text_lg ]
                            ]
                        ]
                        [ text "Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat fugiat aliqua." ]
                    , div
                        [ css
                            [ Tw.mt_5
                            , Tw.max_w_md
                            , Tw.mx_auto
                            , Bp.md [ Tw.mt_8 ]
                            , Bp.sm [ Tw.flex, Tw.justify_center ]
                            ]
                        ]
                        [ getStarted, liveDemo ]
                    , div [ css [ Tw.w_full, Tw.flex, Tw.justify_center ] ]
                        [ div
                            [ css [ Tw.mt_10, Tw.w_1over3, Tw.flex, Tw.justify_center ] ]
                            [ NumberInput.view config.left ]
                        ]
                    , div [ css [ Tw.w_full, Tw.flex, Tw.justify_center ] ]
                        [ div
                            [ css [ Tw.mt_10, Tw.w_1over3, Tw.flex, Tw.justify_center ] ]
                            [ NumberInput.view config.right ]
                        ]
                    , div [ css [ Tw.w_full, Tw.flex, Tw.justify_center ] ]
                        [ div
                            [ css [ Tw.mt_10, Tw.w_1over3, Tw.flex, Tw.justify_center ] ]
                            [ addButton config.onSubmit ]
                        ]
                    ]
                ]
            ]
        ]


liveDemo : Html msg
liveDemo =
    div
        [ css [ Tw.mt_3, Tw.rounded_md, Tw.shadow, Bp.sm [ Tw.mt_0, Tw.ml_3 ] ] ]
        [ a
            [ Attr.href "#"
            , css
                [ Tw.w_full
                , Tw.flex
                , Tw.items_center
                , Tw.justify_center
                , Tw.px_8
                , Tw.py_3
                , Tw.border
                , Tw.border_transparent
                , Tw.text_base
                , Tw.font_medium
                , Tw.rounded_md
                , Tw.text_indigo_600
                , Tw.bg_white
                , Css.hover [ Tw.bg_gray_50 ]
                , Bp.md [ Tw.py_4, Tw.text_lg, Tw.px_10 ]
                ]
            ]
            [ text "Live demo" ]
        ]


getStarted : Html msg
getStarted =
    div [ css [ Tw.rounded_md, Tw.shadow ] ]
        [ a
            [ Attr.href "#"
            , css
                [ Tw.w_full
                , Tw.flex
                , Tw.items_center
                , Tw.justify_center
                , Tw.px_8
                , Tw.py_3
                , Tw.border
                , Tw.border_transparent
                , Tw.text_base
                , Tw.font_medium
                , Tw.rounded_md
                , Tw.text_white
                , Tw.bg_indigo_600
                , Css.hover [ Tw.bg_indigo_700 ]
                , Bp.md [ Tw.py_4, Tw.text_lg, Tw.px_10 ]
                ]
            ]
            [ text "Get started" ]
        ]


addButton : msg -> Html msg
addButton onClick =
    div [ css [ Tw.rounded_md, Tw.shadow ] ]
        [ button
            [ Events.onClick onClick
            , css
                [ Tw.w_full
                , Tw.flex
                , Tw.items_center
                , Tw.justify_center
                , Tw.px_8
                , Tw.py_3
                , Tw.border
                , Tw.border_transparent
                , Tw.text_base
                , Tw.font_medium
                , Tw.rounded_md
                , Tw.text_white
                , Tw.bg_indigo_600
                , Css.hover [ Tw.bg_indigo_700 ]
                , Bp.md [ Tw.py_4, Tw.text_lg, Tw.px_10 ]
                ]
            ]
            [ text "Add Ints in SQL!" ]
        ]
