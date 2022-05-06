module Api.Subscriptions exposing
    ( LobbyData
    , RoomData
    , lobbyUpdatesDecoder
    , lobbyUpdatesDocument
    )

import Graphql.Document
import Graphql.Operation exposing (RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Json.Decode exposing (Decoder)
import VibeSpam.Object as Object
import VibeSpam.Object.LobbyResponse as LobbyResponse
import VibeSpam.Object.Room as Room
import VibeSpam.ScalarCodecs as ScalarCodecs exposing (Uuid)
import VibeSpam.Subscription as Subscription


lobbyUpdates : SelectionSet LobbyData RootSubscription
lobbyUpdates =
    Subscription.lobbyUpdates lobbySelection


lobbyUpdatesDecoder : Decoder LobbyData
lobbyUpdatesDecoder =
    Graphql.Document.decoder lobbyUpdates


lobbyUpdatesDocument : String
lobbyUpdatesDocument =
    Graphql.Document.serializeSubscription lobbyUpdates


lobbySelection : SelectionSet LobbyData Object.LobbyResponse
lobbySelection =
    SelectionSet.map LobbyData
        (LobbyResponse.rooms roomSelection)


roomSelection : SelectionSet RoomData Object.Room
roomSelection =
    SelectionSet.map2 RoomData
        Room.id
        Room.title


type alias LobbyData =
    { rooms : List RoomData
    }


type alias RoomData =
    { id : Uuid
    , title : String
    }
