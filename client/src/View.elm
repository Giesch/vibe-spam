module View exposing
    ( View
    , map
    , none
    , placeholder
    , toBrowserDocument
    )

import Browser
import Css.Global
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attrs
import Tailwind.Utilities as Tw


type alias View msg =
    { title : String
    , body : List (Html msg)
    }


placeholder : String -> View msg
placeholder str =
    { title = str
    , body = [ Html.text str ]
    }


none : View msg
none =
    placeholder ""


map : (a -> b) -> View a -> View b
map fn view =
    { title = view.title
    , body = List.map (Html.map fn) view.body
    }


toBrowserDocument : View msg -> Browser.Document msg
toBrowserDocument view =
    let
        screen : Html msg
        screen =
            Html.div [ Attrs.css [ Tw.flex, Tw.flex_col, Tw.h_screen ] ]
                (Css.Global.global Tw.globalStyles :: view.body)
    in
    { title = view.title
    , body = [ Html.toUnstyled screen ]
    }
