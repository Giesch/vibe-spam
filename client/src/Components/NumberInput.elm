module Components.NumberInput exposing
    ( Config
    , view
    )

import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Config msg =
    { onInput : String -> msg
    , value : String
    , valid : Bool
    }


intId : String
intId =
    "int"


view : Config msg -> Html msg
view config =
    div []
        [ label
            [ Attr.for intId
            , css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700 ]
            ]
            [ text "Int" ]
        , div
            [ css [ Tw.mt_1, Tw.relative, Tw.rounded_md, Tw.shadow_sm ] ]
            [ div
                [ css
                    [ Tw.absolute
                    , Tw.inset_y_0
                    , Tw.left_0
                    , Tw.pl_3
                    , Tw.flex
                    , Tw.items_center
                    , Tw.pointer_events_none
                    ]
                ]
                [ span [ css [ Tw.text_gray_500, Bp.sm [ Tw.text_sm ] ] ] [ text "$" ] ]
            , input
                [ Events.onInput config.onInput
                , Attr.value config.value
                , Attr.type_ "text"
                , Attr.name intId
                , Attr.id intId
                , css
                    [ Tw.block
                    , Tw.w_full
                    , Tw.pl_7
                    , Tw.pr_12
                    , Tw.border_gray_300
                    , Tw.rounded_md
                    , Css.focus <|
                        if config.valid then
                            [ Tw.ring_indigo_500, Tw.border_indigo_500 ]

                        else
                            [ Tw.ring_red_500, Tw.border_red_500 ]
                    , Bp.sm [ Tw.text_sm ]
                    ]
                , Attr.placeholder "0"
                ]
                []
            ]
        ]
