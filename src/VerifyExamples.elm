port module VerifyExamples exposing (..)

import Cmd.Util as Cmd
import Json.Decode as Decode exposing (Decoder, Value, decodeValue, field, list, string)
import Platform
import VerifyExamples.Compiler as Compiler
import VerifyExamples.ModuleName as ModuleName exposing (ModuleName)
import VerifyExamples.Parser as Parser
import VerifyExamples.Warning as Warning exposing (Warning)
import VerifyExamples.Warning.Ignored as Ignored exposing (Ignored)


main : Program Value () Msg
main =
    Platform.programWithFlags
        { init = init >> (,) ()
        , update = \msg _ -> ( (), update msg )
        , subscriptions = subscriptions
        }



-- MODEL


init : Value -> Cmd Msg
init flags =
    case decodeValue decoder flags of
        Ok tests ->
            tests
                |> List.map (ReadTest >> Cmd.perform)
                |> Cmd.batch

        Err err ->
            Debug.crash err


decoder : Decoder (List String)
decoder =
    Decode.at [ "tests", "elm" ] (list string)



-- UPDATE


type Msg
    = ReadTest String
    | CompileModule CompileInfo


update : Msg -> Cmd Msg
update msg =
    case msg of
        ReadTest test ->
            readFile test

        CompileModule info ->
            case generateTests info of
                ( warnings, compiled ) ->
                    Cmd.batch
                        [ compiled
                            |> List.map (Tuple.mapFirst ModuleName.toString)
                            |> writeFiles
                        , warnings
                            |> List.map Warning.toString
                            |> curry warn (ModuleName.toString info.moduleName)
                        ]


generateTests : CompileInfo -> ( List Warning, List ( ModuleName, String ) )
generateTests { moduleName, fileText, ignoredWarnings } =
    let
        parsed =
            Parser.parse fileText
    in
    ( Warning.warnings ignoredWarnings parsed
    , List.concatMap (Compiler.compile moduleName) parsed.testSuites
    )



-- PORTS


port readFile : String -> Cmd msg


port writeFiles : List ( String, String ) -> Cmd msg


port generateModuleVerifyExamples : (Value -> msg) -> Sub msg


port warn : ( String, List String ) -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : () -> Sub Msg
subscriptions _ =
    generateModuleVerifyExamples
        (\value ->
            case decodeValue decodeCompileInfo value of
                Ok info ->
                    CompileModule info

                Err err ->
                    Debug.crash "TODO"
        )


type alias CompileInfo =
    { moduleName : ModuleName
    , fileText : String
    , ignoredWarnings : List Ignored
    }


decodeCompileInfo : Decoder CompileInfo
decodeCompileInfo =
    Decode.map3 CompileInfo
        (field "moduleName" string
            |> Decode.map ModuleName.fromString
        )
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
