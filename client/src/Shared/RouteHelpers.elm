module Shared.RouteHelpers exposing
    ( home
    , notFound
    , rooms
    )

import Gen.Route as Route exposing (Route)


home : Route
home =
    Route.Home_


notFound : Route
notFound =
    Route.NotFound


rooms : { slug : String } -> Route
rooms params =
    Route.Rooms__Slug_ params
