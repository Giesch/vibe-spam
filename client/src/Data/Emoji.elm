module Data.Emoji exposing
    ( Emoji
    , all
    , fromGraphql
    , toGraphql
    , toString
    )

import VibeSpam.Enum.Emoji as Gql


type Emoji
    = SweatSmile
    | Smile
    | Heart
    | Crying
    | UpsideDown
    | Party


fromGraphql : Gql.Emoji -> Emoji
fromGraphql gqlEmoji =
    case gqlEmoji of
        Gql.SweatSmile ->
            SweatSmile

        Gql.Smile ->
            Smile

        Gql.Heart ->
            Heart

        Gql.Crying ->
            Crying

        Gql.UpsideDown ->
            UpsideDown

        Gql.Party ->
            Party


toGraphql : Emoji -> Gql.Emoji
toGraphql emoji =
    case emoji of
        SweatSmile ->
            Gql.SweatSmile

        Smile ->
            Gql.Smile

        Heart ->
            Gql.Heart

        Crying ->
            Gql.Crying

        UpsideDown ->
            Gql.UpsideDown

        Party ->
            Gql.Party


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


all : List Emoji
all =
    [ SweatSmile
    , Smile
    , Heart
    , Crying
    , UpsideDown
    , Party
    ]
