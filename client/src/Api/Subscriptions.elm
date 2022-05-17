module Api.Subscriptions exposing
    ( ChatMessageData
    , LobbyData
    , RoomData
    , chatRoomUpdatesDecoder
    , chatRoomUpdatesDocument
    , lobbyUpdatesDecoder
    , lobbyUpdatesDocument
    )

import Graphql.Document
import Graphql.Operation exposing (RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Json.Decode exposing (Decoder)
import ScalarCodecs.Uuid as Uuid exposing (Uuid)
import VibeSpam.Enum.Emoji exposing (Emoji)
import VibeSpam.Object as Object
import VibeSpam.Object.ChatMessage as ChatMessage
import VibeSpam.Object.Lobby as Lobby
import VibeSpam.Object.Room as Room
import VibeSpam.ScalarCodecs exposing (DateTime)
import VibeSpam.Subscription as Subscription


chatRoomUpdates :
    { roomTitle : String }
    -> SelectionSet (List ChatMessageData) RootSubscription
chatRoomUpdates args =
    Subscription.chatRoomUpdates args chatRoomSelection


chatRoomUpdatesDocument : { roomTitle : String } -> String
chatRoomUpdatesDocument args =
    Graphql.Document.serializeSubscription (chatRoomUpdates args)


chatRoomUpdatesDecoder : { roomTitle : String } -> Decoder (List ChatMessageData)
chatRoomUpdatesDecoder args =
    Graphql.Document.decoder (chatRoomUpdates args)


lobbyUpdates : SelectionSet LobbyData RootSubscription
lobbyUpdates =
    Subscription.lobbyUpdates lobbySelection


lobbyUpdatesDecoder : Decoder LobbyData
lobbyUpdatesDecoder =
    Graphql.Document.decoder lobbyUpdates


lobbyUpdatesDocument : String
lobbyUpdatesDocument =
    Graphql.Document.serializeSubscription lobbyUpdates


type alias LobbyData =
    { rooms : List RoomData
    }


lobbySelection : SelectionSet LobbyData Object.Lobby
lobbySelection =
    SelectionSet.map LobbyData (Lobby.rooms roomSelection)


type alias RoomData =
    { id : Uuid
    , title : String
    }


roomSelection : SelectionSet RoomData Object.Room
roomSelection =
    SelectionSet.map2 RoomData
        Room.id
        Room.title


type alias ChatMessageData =
    { id : Uuid
    , authorSessionId : Uuid
    , emoji : Emoji
    , updatedAt : DateTime
    }


chatRoomSelection : SelectionSet ChatMessageData Object.ChatMessage
chatRoomSelection =
    SelectionSet.map4 ChatMessageData
        ChatMessage.id
        ChatMessage.authorSessionId
        ChatMessage.emoji
        ChatMessage.updatedAt
