module Api exposing
    ( GraphqlData
    , LobbyData
    , RoomData
    , createRoom
    , fetchLobby
    )

import Config
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData)
import VibeSpam.Mutation as Mutation
import VibeSpam.Object as Object
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


lobbySelection : SelectionSet LobbyData Object.LobbyResponse
lobbySelection =
    SelectionSet.map LobbyData
        (LobbyResponse.rooms roomSelection)


roomSelection : SelectionSet RoomData Object.Room
roomSelection =
    SelectionSet.map RoomData Room.title


fetchLobby : (GraphqlData LobbyData -> msg) -> Effect msg
fetchLobby toMsg =
    queryEffect toMsg lobbyQuery


createRoom : SelectionSet RoomData RootMutation
createRoom =
    Mutation.createRoom roomSelection



-- Helpers


queryEffect :
    (GraphqlData resp -> msg)
    -> SelectionSet resp RootQuery
    -> Effect msg
queryEffect toMsg query =
    query
        |> Graphql.Http.queryRequest endpoint
        |> Graphql.Http.send (RemoteData.fromResult >> toMsg)
        |> Effect.fromCmd


endpoint : String
endpoint =
    Config.apiTarget ++ "/api/graphql"
