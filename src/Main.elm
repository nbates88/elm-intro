module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http

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
    { quote : String
    }

init : () -> (Model, Cmd Msg)
init _ =
     ( Model "", fetchRandomQuoteCmd )

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


randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"



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
            ( { model | quote = newQuote }, Cmd.none )

        Err _ ->
            ( model, Cmd.none )

-- UPDATE

type Msg 
    = GetQuote 
    | FetchRandomQuoteCompleted (Result Http.Error String)  

update : Msg -> Model -> (Model, Cmd Msg)

update msg model =
    case msg of
        GetQuote ->
            ( model, fetchRandomQuoteCmd )
        FetchRandomQuoteCompleted result ->
            fetchRandomQuoteCompleted model result


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
    div [ class "container" ] [
        h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
        , p [ class "text-center" ] [
            button [ class "btn btn-success", onClick GetQuote ] [ text "Grab a quote!" ]
        ]
        -- Blockquote with quote
        , blockquote [] [
            p [] [text model.quote]
        ]
    ]