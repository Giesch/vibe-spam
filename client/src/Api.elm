module Api exposing
    ( GraphqlData
    , createMessage
    , createRoom
    )

import Api.RoomData exposing (RoomData)
import Config
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootMutation)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData)
import VibeSpam.Mutation as Mutation exposing (CreateMessageRequiredArguments)
import VibeSpam.Object as Object
import VibeSpam.Object.Room as Room



-- PUBLIC


type alias GraphqlData a =
    RemoteData (Graphql.Http.Error ()) a


createRoom : (GraphqlData RoomData -> msg) -> Effect msg
createRoom toMsg =
    mutationEffect toMsg createRoomMutation


createMessage : (GraphqlData () -> msg) -> CreateMessageRequiredArguments -> Effect msg
createMessage toMsg args =
    mutationEffect toMsg (createMessageMutation args)



-- SELECTIONS


createRoomMutation : SelectionSet RoomData RootMutation
createRoomMutation =
    Mutation.createRoom roomSelection


roomSelection : SelectionSet RoomData Object.Room
roomSelection =
    SelectionSet.map3 RoomData
        Room.id
        Room.title
        Room.updatedAt


createMessageMutation : CreateMessageRequiredArguments -> SelectionSet () RootMutation
createMessageMutation args =
    Mutation.createMessage args SelectionSet.empty



-- EFFECTS


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
