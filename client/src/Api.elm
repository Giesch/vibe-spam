module Api exposing
    ( GraphqlData
    , LobbyData
    , RoomData
    , createRoom
    )

import Config
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData)
import VibeSpam.Mutation as Mutation
import VibeSpam.Object as Object
import VibeSpam.Object.Room as Room



-- PUBLIC


type alias GraphqlData a =
    RemoteData (Graphql.Http.Error ()) a


type alias LobbyData =
    { rooms : List RoomData
    }


type alias RoomData =
    { title : String
    }


createRoom : (GraphqlData RoomData -> msg) -> Effect msg
createRoom toMsg =
    mutationEffect toMsg createRoomMutation



-- SELECTIONS


createRoomMutation : SelectionSet RoomData RootMutation
createRoomMutation =
    Mutation.createRoom roomSelection


roomSelection : SelectionSet RoomData Object.Room
roomSelection =
    SelectionSet.map RoomData Room.title



-- EFFECTS


queryEffect :
    (GraphqlData resp -> msg)
    -> SelectionSet resp RootQuery
    -> Effect msg
queryEffect toMsg selection =
    selection
        |> Graphql.Http.queryRequest endpoint
        |> Graphql.Http.send
            (Graphql.Http.discardParsedErrorData >> RemoteData.fromResult >> toMsg)
        |> Effect.fromCmd


mutationEffect :
    (GraphqlData resp -> msg)
    -> SelectionSet resp RootMutation
    -> Effect msg
mutationEffect toMsg selection =
    selection
        |> Graphql.Http.mutationRequest endpoint
        |> Graphql.Http.send
            (Graphql.Http.discardParsedErrorData >> RemoteData.fromResult >> toMsg)
        |> Effect.fromCmd


endpoint : String
endpoint =
    Config.apiTarget ++ "/api/graphql"
