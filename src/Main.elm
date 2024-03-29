port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
-- MAIN


main =
 Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL

type alias Model =
     { username : String
    , password : String
    , token : String
    , quote : String
    , protectedQuote : String
    , errorMsg : String
    }


init : Maybe Model -> (Model, Cmd Msg)
init model =
    case model of
        Just initModel ->
            ( initModel, fetchRandomQuoteCmd )
        Nothing ->
            ( Model "" "" "" "" "" "", fetchRandomQuoteCmd )
{-
   UPDATE
   * API routes
   * GET
   * Messages
   * Update case
-}
-- API request URLs


api : String
api =
    "http://localhost:3001/"

registerUrl : String
registerUrl =
    api ++ "users"

loginUrl : String
loginUrl =
    api ++ "sessions/create"

randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"

protectedQuoteUrl : String
protectedQuoteUrl =
    api ++ "api/protected/random-quote"
-- GET a random quote (unauthenticated)


fetchRandomQuote : Http.Request String
fetchRandomQuote =
    Http.getString randomQuoteUrl


fetchRandomQuoteCmd : Cmd Msg
fetchRandomQuoteCmd =
    Http.send FetchRandomQuoteCompleted fetchRandomQuote


fetchRandomQuoteCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
fetchRandomQuoteCompleted model result =
    case result of
        Ok newQuote ->
           setStorageHelper { model | quote = newQuote }

        Err _ ->
            ( model, Cmd.none )

-- Encode user to construct POST request body (for Register and Log In)

userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ("username", Encode.string model.username)
        , ("password", Encode.string model.password)
        ]          


-- POST register / login request


authUser : Model -> String -> Http.Request String
authUser model apiUrl =
    let
        body =
            model
                |> userEncoder
                |> Http.jsonBody
    in
        Http.post apiUrl body tokenDecoder


authUserCmd : Model -> String -> Cmd Msg
authUserCmd model apiUrl =
    Http.send GetTokenCompleted (authUser model apiUrl)


getTokenCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
getTokenCompleted model result =
    case result of
        Ok newToken ->
            setStorageHelper { model | token = newToken, password = "", errorMsg = "" }

        Err error ->
            ( { model | errorMsg = "There was some error" }, Cmd.none )

--Decode POST response to get access token


tokenDecoder : Decoder String
tokenDecoder =
    Decode.field "access_token" Decode.string

fetchProtectedQuote : Model -> Http.Request String
fetchProtectedQuote model =
    { method = "GET"
    , headers = [ Http.header "Authorization" ("Bearer " ++ model.token) ]
    , url = protectedQuoteUrl
    , body = Http.emptyBody
    , expect = Http.expectString
    , timeout = Nothing
    , withCredentials = False
    }
        |> Http.request


fetchProtectedQuoteCmd : Model -> Cmd Msg
fetchProtectedQuoteCmd model =
    Http.send FetchProtectedQuoteCompleted (fetchProtectedQuote model)


fetchProtectedQuoteCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
fetchProtectedQuoteCompleted model result =
    case result of
        Ok newPQuote ->
            setStorageHelper { model | protectedQuote = newPQuote }

        Err _ ->
            ( model, Cmd.none )

-- Helper to update model and set localStorage with the updated model

setStorageHelper : Model -> ( Model, Cmd Msg )
setStorageHelper model =
    ( model, setStorage model )

-- Ports


port setStorage : Model -> Cmd msg


port removeStorage : Model -> Cmd msg

-- UPDATE

type Msg 
    = GetQuote 
    | FetchRandomQuoteCompleted (Result Http.Error String)  
    | GetProtectedQuote
    | FetchProtectedQuoteCompleted (Result Http.Error String)
    | SetUsername String
    | SetPassword String
    | ClickRegisterUser
    | ClickLogIn
    | GetTokenCompleted (Result Http.Error String)
    | LogOut


update : Msg -> Model -> (Model, Cmd Msg)

update msg model =
    case msg of
        GetQuote ->
            ( model, fetchRandomQuoteCmd )
        FetchRandomQuoteCompleted result ->
            fetchRandomQuoteCompleted model result
        GetProtectedQuote ->
            ( model, fetchProtectedQuoteCmd model )
        FetchProtectedQuoteCompleted result ->
            fetchProtectedQuoteCompleted model result  
        SetUsername username ->
            ( { model | username = username }, Cmd.none )
        SetPassword password ->
            ( { model | password = password }, Cmd.none )
        ClickRegisterUser ->
            ( model, authUserCmd model registerUrl )
        ClickLogIn ->
            ( model, authUserCmd model loginUrl )
        GetTokenCompleted result ->
            getTokenCompleted model result
        LogOut ->
            ( { model | username = "", token = "" }, removeStorage model )

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
    let
        -- Is the user logged in?
        loggedIn : Bool
        loggedIn =
            if String.length model.token > 0 then
                True
            else
                False

        -- If the user is logged in, show a greeting; if logged out, show the login/register form
        authBoxView =
            let
                -- If there is an error on authentication, show the error alert
                showError : String
                showError =
                    if String.isEmpty model.errorMsg then
                        "hidden"
                    else
                        ""

                -- Greet a logged in user by username
                greeting : String
                greeting =
                    "Hello, " ++ model.username ++ "!"
            in
                if loggedIn then
                    div [ id "greeting" ]
                        [ h3 [ class "text-center" ] [ text greeting ]
                        , p [ class "text-center" ] [ text "You have super-secret access to protected quotes." ]
                        , p [ class "text-center" ]
                            [ button [ class "btn btn-danger", onClick LogOut ] [ text "Log Out" ]
                            ]
                        ]
                else
                    div [ id "form" ]
                        [ h2 [ class "text-center" ] [ text "Log In or Register" ]
                        , p [ class "help-block" ] [ text "If you already have an account, please Log In. Otherwise, enter your desired username and password and Register." ]
                        , div [ class showError ]
                            [ div [ class "alert alert-danger" ] [ text model.errorMsg ]
                            ]
                        , div [ class "form-group row" ]
                            [ div [ class "col-md-offset-2 col-md-8" ]
                                [ label [ for "username" ] [ text "Username:" ]
                                , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.username, onInput SetUsername ] []
                                ]
                            ]
                        , div [ class "form-group row" ]
                            [ div [ class "col-md-offset-2 col-md-8" ]
                                [ label [ for "password" ] [ text "Password:" ]
                                , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput SetPassword ] []
                                ]
                            ]
                        , div [ class "text-center" ] [
                            button [ class "btn btn-primary", onClick ClickLogIn ] [ text "Log In" ]
                            , button [ class "btn btn-link", onClick ClickRegisterUser ] [ text "Register" ]
                            ]
                        ]
        -- If user is logged in, show button and quote; if logged out, show a message instructing them to log in
        protectedQuoteView =
            let
                -- If no protected quote, apply a class of "hidden"
                hideIfNoProtectedQuote : String
                hideIfNoProtectedQuote =
                    if String.isEmpty model.protectedQuote then
                        "hidden"
                    else
                        ""
            in
                if loggedIn then
                    div []
                        [ p [ class "text-center" ]
                            [ button [ class "btn btn-info", onClick GetProtectedQuote ] [ text "Grab a protected quote!" ]
                            ]
                          -- Blockquote with protected quote: only show if a protectedQuote is present in model
                        , blockquote [ class hideIfNoProtectedQuote ]
                            [ p [] [ text model.protectedQuote ]
                            ]
                        ]
                else
                    p [ class "text-center" ] [ text "Please log in or register to see protected quotes." ]
    in
        div [ class "container" ]
            [ h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
            , p [ class "text-center" ]
                [ button [ class "btn btn-success", onClick GetQuote ] [ text "Grab a quote!" ]
                ]
              -- Blockquote with quote
            , blockquote []
                [ p [] [ text model.quote ]
                ]
            , div [ class "jumbotron text-left" ]
                [ -- Login/Register form or user greeting
                  authBoxView
                ]
            , div []
                [ h2 [ class "text-center" ] [ text "Protected Chuck Norris Quotes" ]
                  -- Protected quotes
                , protectedQuoteView
                ]
            ]
