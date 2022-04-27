module Main exposing (main)

import Browser
import Browser.Navigation as Nav exposing (Key)
import Effect exposing (Effect)
import Gen.Model
import Gen.Pages as Pages
import Gen.Route as Route
import Json.Decode as Decode
import Ports
import Request
import Shared
import Url exposing (Url)
import View


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }



-- INIT


type alias Model =
    { url : Url
    , key : Key
    , shared : Shared.Model
    , page : Pages.Model
    }


init : Decode.Value -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( shared, sharedCmd ) =
            Shared.init (Request.create () url key) flags

        ( page, effect ) =
            Pages.init (Route.fromUrl url) shared url key
    in
    ( Model url key shared page
    , Cmd.batch
        [ Cmd.map Shared sharedCmd
        , effectToCmd effect
        ]
    )



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | Shared Shared.Msg
    | Page Pages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink (Browser.Internal url) ->
            let
                stringUrl =
                    Url.toString url

                navCmd =
                    if isOutgoingOauthPath stringUrl then
                        Nav.load stringUrl

                    else
                        Nav.pushUrl model.key stringUrl
            in
            ( model
            , Cmd.batch [ navCmd, graphqlUnsubscribe ]
            )

        ClickedLink (Browser.External url) ->
            ( model
            , Cmd.batch [ Nav.load url, graphqlUnsubscribe ]
            )

        ChangedUrl url ->
            if url.path /= model.url.path then
                let
                    -- TODO gql unsubscribe before this
                    ( page, effect ) =
                        Pages.init (Route.fromUrl url) model.shared url model.key
                in
                ( { model | url = url, page = page }
                , effectToCmd effect
                )

            else
                ( { model | url = url }, Cmd.none )

        Shared sharedMsg ->
            let
                ( shared, sharedCmd ) =
                    Shared.update (Request.create () model.url model.key) sharedMsg model.shared

                -- TODO gql unsubscribe before this
                ( page, effect ) =
                    Pages.init (Route.fromUrl model.url) shared model.url model.key
            in
            if page == Gen.Model.Redirecting_ then
                ( { model | shared = shared, page = page }
                , Cmd.batch
                    [ Cmd.map Shared sharedCmd
                    , effectToCmd effect
                    ]
                )

            else
                ( { model | shared = shared }
                , Cmd.map Shared sharedCmd
                )

        Page pageMsg ->
            let
                ( page, effect ) =
                    Pages.update pageMsg model.page model.shared model.url model.key
            in
            ( { model | page = page }
            , effectToCmd effect
            )


graphqlUnsubscribe : Cmd Msg
graphqlUnsubscribe =
    effectToCmd Ports.lobbyUnsubscribe


effectToCmd : Effect Pages.Msg -> Cmd Msg
effectToCmd effect =
    Effect.toCmd ( Shared, Page ) effect


isOutgoingOauthPath : String -> Bool
isOutgoingOauthPath path =
    String.endsWith Shared.googleOauthPath path



-- VIEW


view : Model -> Browser.Document Msg
view model =
    Pages.view model.page model.shared model.url model.key
        |> View.map Page
        |> View.toBrowserDocument



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pages.subscriptions model.page model.shared model.url model.key
            |> Sub.map Page
        , Shared.subscriptions (Request.create () model.url model.key) model.shared
            |> Sub.map Shared
        ]
