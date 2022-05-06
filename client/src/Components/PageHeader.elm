module Components.PageHeader exposing (view)

import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attrs exposing (css)
import Tailwind.Utilities as Tw


view : Html msg
view =
    let
        headerStyles : List Css.Style
        headerStyles =
            [ Tw.bg_green_500
            , Tw.text_white
            , Tw.p_6
            , Tw.flex
            , Tw.items_end
            , Tw.space_x_10
            ]
    in
    header [ css headerStyles ]
        [ div [ css [ Tw.text_2xl, Tw.font_bold, Tw.pr_12 ] ]
            [ text "vibespam" ]
        , tabLink { name = "lobby", href = "/" }
        ]


tabLink : { name : String, href : String } -> Html msg
tabLink { name, href } =
    a [ css [ Tw.text_lg ], Attrs.href href ]
        [ text name ]
