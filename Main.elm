module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias IndicatorDatum =
    { countryId : String
    , countryName : String
    , year : String
    , value : Maybe Float
    }


type alias Model =
    { indicator : String
    , data : List IndicatorDatum
    }


init : ( Model, Cmd Msg )
init =
    ( { indicator = "EG.FEC.RNEW.ZS"
      , data = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = RequestData
    | NewData (Result Http.Error (List IndicatorDatum))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RequestData ->
            ( model, getData model.indicator )

        NewData (Ok data) ->
            ( { model | data = data }, Cmd.none )

        NewData (Err error) ->
            let
                _ =
                    Debug.log "error" error
            in
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        stringValue : Maybe Float -> String
        stringValue value =
            case value of
                Just value ->
                    toString value

                Nothing ->
                    "-"
    in
    div []
        [ h2 [] [ text model.indicator ]
        , button [ onClick RequestData ] [ text "Request Data!" ]
        , div [ class "data" ]
            [ ul [] <|
                List.map
                    (\d ->
                        li [] [ text <| d.countryName ++ ": " ++ stringValue d.value ]
                    )
                    model.data
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


getData : String -> Cmd Msg
getData indicator =
    let
        url =
            "https://api.worldbank.org/v2/countries/all/indicators/"
                ++ indicator
                ++ "?date=2002:2002&format=json&per_page=500"
    in
    Http.send NewData (Http.get url decodeResponse)


decodeIndicator : Decode.Decoder IndicatorDatum
decodeIndicator =
    Decode.map4 IndicatorDatum
        (Decode.at [ "country", "id" ] Decode.string)
        (Decode.at [ "country", "value" ] Decode.string)
        (Decode.field "date" Decode.string)
        (Decode.field "value" <| Decode.maybe Decode.float)


decodeResponse : Decode.Decoder (List IndicatorDatum)
decodeResponse =
    Decode.index 1 (Decode.list decodeIndicator)
