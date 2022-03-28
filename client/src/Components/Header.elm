module Components.Header exposing (view)

import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Shared
import Svg.Styled as Svg exposing (path, svg)
import Svg.Styled.Attributes as SvgAttr
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


view : Html msg
view =
    header [ css [ Tw.bg_indigo_600 ] ]
        [ nav
            [ css
                [ Tw.max_w_7xl
                , Tw.mx_auto
                , Tw.px_4
                , Bp.lg [ Tw.px_8 ]
                , Bp.sm [ Tw.px_6 ]
                ]
            , Attr.attribute "aria-label" "Top"
            ]
            [ div
                [ css
                    [ Tw.w_full
                    , Tw.py_6
                    , Tw.flex
                    , Tw.items_center
                    , Tw.justify_between
                    , Tw.border_b
                    , Tw.border_indigo_500
                    , Bp.lg [ Tw.border_none ]
                    ]
                ]
                [ div [ css [ Tw.flex, Tw.items_center ] ]
                    [ a [ Attr.href "#" ]
                        [ span [ css [ Tw.sr_only ] ] [ text "Workflow" ]
                        , tailwindSassLogo
                        ]
                    , div
                        [ css [ Tw.hidden, Tw.ml_10, Tw.space_x_8, Bp.lg [ Tw.block ] ] ]
                        sectionLinks
                    ]
                , div [ css [ Tw.ml_10, Tw.space_x_4 ] ]
                    [ signInLink, signUpLink ]
                ]
            , div
                [ css
                    [ Tw.py_4
                    , Tw.flex
                    , Tw.flex_wrap
                    , Tw.justify_center
                    , Tw.space_x_6
                    , Bp.lg [ Tw.hidden ]
                    ]
                ]
                sectionLinks
            ]
        ]


signInLink : Html msg
signInLink =
    a
        [ Attr.href Shared.googleOauthPath
        , css
            ([ Tw.bg_indigo_500
             , Tw.text_white
             , Css.hover [ Tw.bg_opacity_75 ]
             ]
                ++ sharedButtonStyles
            )
        ]
        [ text "Sign in" ]


signUpLink : Html msg
signUpLink =
    a
        [ Attr.href "#"
        , css
            ([ Tw.bg_white
             , Tw.text_indigo_600
             , Css.hover [ Tw.bg_indigo_50 ]
             ]
                ++ sharedButtonStyles
            )
        ]
        [ text "Sign up" ]


sharedButtonStyles : List Css.Style
sharedButtonStyles =
    [ Tw.inline_block
    , Tw.py_2
    , Tw.px_4
    , Tw.border
    , Tw.border_transparent
    , Tw.rounded_md
    , Tw.text_base
    , Tw.font_medium
    ]


sectionLinks : List (Html msg)
sectionLinks =
    List.map mockLink
        [ "Home", "About" ]


type alias LinkConfig =
    { href : String
    , title : String
    }


mockLink : String -> Html msg
mockLink title =
    link { title = title, href = "#" }


link : LinkConfig -> Html msg
link config =
    a
        [ Attr.href config.href
        , css
            [ Tw.text_base
            , Tw.font_medium
            , Tw.text_white
            , Css.hover [ Tw.text_indigo_50 ]
            ]
        ]
        [ text config.title ]


tailwindSassLogo : Html msg
tailwindSassLogo =
    svg
        [ SvgAttr.css [ Tw.h_10, Tw.w_auto ]
        , SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 35 32"
        ]
        [ path
            [ SvgAttr.fill "#fff"
            , SvgAttr.d "M15.258 26.865a4.043 4.043 0 01-1.133 2.917A4.006 4.006 0 0111.253 31a3.992 3.992 0 01-2.872-1.218 4.028 4.028 0 01-1.133-2.917c.009-.698.2-1.382.557-1.981.356-.6.863-1.094 1.47-1.433-.024.109.09-.055 0 0l1.86-1.652a8.495 8.495 0 002.304-5.793c0-2.926-1.711-5.901-4.17-7.457.094.055-.036-.094 0 0A3.952 3.952 0 017.8 7.116a3.975 3.975 0 01-.557-1.98 4.042 4.042 0 011.133-2.918A4.006 4.006 0 0111.247 1a3.99 3.99 0 012.872 1.218 4.025 4.025 0 011.133 2.917 8.521 8.521 0 002.347 5.832l.817.8c.326.285.668.551 1.024.798.621.33 1.142.826 1.504 1.431a3.902 3.902 0 01-1.504 5.442c.033-.067-.063.036 0 0a8.968 8.968 0 00-3.024 3.183 9.016 9.016 0 00-1.158 4.244zM19.741 5.123c0 .796.235 1.575.676 2.237a4.01 4.01 0 001.798 1.482 3.99 3.99 0 004.366-.873 4.042 4.042 0 00.869-4.386 4.02 4.02 0 00-1.476-1.806 3.994 3.994 0 00-5.058.501 4.038 4.038 0 00-1.175 2.845zM23.748 22.84c-.792 0-1.567.236-2.226.678a4.021 4.021 0 00-1.476 1.806 4.042 4.042 0 00.869 4.387 3.99 3.99 0 004.366.873A4.01 4.01 0 0027.08 29.1a4.039 4.039 0 00-.5-5.082 4 4 0 00-2.832-1.18zM34 15.994c0-.796-.235-1.574-.675-2.236a4.01 4.01 0 00-1.798-1.483 3.99 3.99 0 00-4.367.873 4.042 4.042 0 00-.869 4.387 4.02 4.02 0 001.476 1.806 3.993 3.993 0 002.226.678 4.003 4.003 0 002.832-1.18A4.04 4.04 0 0034 15.993z M5.007 11.969c-.793 0-1.567.236-2.226.678a4.021 4.021 0 00-1.476 1.807 4.042 4.042 0 00.869 4.386 4.001 4.001 0 004.366.873 4.011 4.011 0 001.798-1.483 4.038 4.038 0 00-.5-5.08 4.004 4.004 0 00-2.831-1.181z"
            ]
            []
        ]
