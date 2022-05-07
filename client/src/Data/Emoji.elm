module Data.Emoji exposing
    ( Emoji(..)
    , all
    , fromString
    , toString
    )


type Emoji
    = SweatSmile
    | Smile
    | Heart
    | Crying
    | UpsideDown
    | Party


toString : Emoji -> String
toString emoji =
    case emoji of
        SweatSmile ->
            "😅"

        Smile ->
            "😊"

        Heart ->
            "❤️"

        Crying ->
            "😭"

        UpsideDown ->
            "🙃"

        Party ->
            "🥳"


fromString : String -> Maybe Emoji
fromString str =
    let
        matches : Emoji -> Bool
        matches emoji =
            str == toString emoji
    in
    List.filter matches all
        |> List.head


all : List Emoji
all =
    [ SweatSmile
    , Smile
    , Heart
    , Crying
    , UpsideDown
    , Party
    ]
