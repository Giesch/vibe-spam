module Api exposing (..)

import Config
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData)
import VibeSpam.Object as Object exposing (LobbyResponse, Room)
import VibeSpam.Object.LobbyResponse as LobbyResponse
import VibeSpam.Object.Room as Room
import VibeSpam.Query as Query


type alias GraphqlData a =
    RemoteData (Graphql.Http.Error a) a


lobbyQuery : SelectionSet LobbyData RootQuery
lobbyQuery =
    Query.lobby lobbySelection


type alias LobbyData =
    { rooms : List RoomData
    }


type alias RoomData =
    { title : String
    }


lobbySelection : SelectionSet LobbyData LobbyResponse
lobbySelection =
    SelectionSet.map LobbyData (LobbyResponse.rooms roomSelection)


roomSelection =
    SelectionSet.map RoomData Room.title
