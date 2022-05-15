module Shared.Routes exposing (rooms)

import Gen.Route as Route exposing (Route)


rooms : { slug : String } -> Route
rooms params =
    Route.Rooms__Slug_ params
