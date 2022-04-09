module Api exposing (..)

import Config
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData)
import VibeSpam.Query as Query


type alias GraphqlData a =
    RemoteData (Graphql.Http.Error a) a
