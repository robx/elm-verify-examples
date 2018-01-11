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
            Cmd.batch <|
                List.append
                    (List.map (ReadElm >> Cmd.perform) tests.elm)
                    (List.map (ReadMarkdown >> Cmd.perform) tests.markdown)

        Err err ->
            Debug.crash err


type alias Sources =
    { elm : List String
    , markdown : List String
    }


decoder : Decoder Sources
decoder =
    field "tests" <|
        Decode.map2 Sources
            (field "elm" (list string))
            (field "markdown" (list string))



-- UPDATE


type Msg
    = ReadElm String
    | ReadMarkdown String
    | CompileModule ElmCompileInfo
    | CompileMarkdown MarkdownCompileInfo


update : Msg -> Cmd Msg
update msg =
    case msg of
        ReadElm test ->
            readElm test

        ReadMarkdown test ->
            readMarkdown test

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

        CompileMarkdown info ->
            -- TODO
            Cmd.none


generateTests : ElmCompileInfo -> ( List Warning, List ( ModuleName, String ) )
generateTests { moduleName, fileText, ignoredWarnings } =
    let
        parsed =
            Parser.parse fileText
    in
    ( Warning.warnings ignoredWarnings parsed
    , List.concatMap (Compiler.compile moduleName) parsed.testSuites
    )



-- PORTS


port readElm : String -> Cmd msg


port readMarkdown : String -> Cmd msg


port writeFiles : List ( String, String ) -> Cmd msg


port generateModuleVerifyExamples : (Value -> msg) -> Sub msg


port generateMarkdownVerifyExamples : (Value -> msg) -> Sub msg


port warn : ( String, List String ) -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : () -> Sub Msg
subscriptions _ =
    Sub.batch
        [ generateModuleVerifyExamples (runDecoder decodeElmCompileInfo >> CompileModule)
        , generateMarkdownVerifyExamples (runDecoder decodeMarkdownCompileInfo >> CompileMarkdown)
        ]


runDecoder : Decoder a -> Value -> a
runDecoder decoder value =
    case decodeValue decoder value of
        Ok info ->
            info

        Err err ->
            Debug.crash "TODO"


type alias ElmCompileInfo =
    { moduleName : ModuleName
    , fileText : String
    , ignoredWarnings : List Ignored
    }


decodeElmCompileInfo : Decoder ElmCompileInfo
decodeElmCompileInfo =
    Decode.map3 ElmCompileInfo
        (field "moduleName" string
            |> Decode.map ModuleName.fromString
        )
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)


type alias MarkdownCompileInfo =
    { filePath : String
    , fileText : String
    , ignoredWarnings : List Ignored
    }


decodeMarkdownCompileInfo : Decoder MarkdownCompileInfo
decodeMarkdownCompileInfo =
    Decode.map3 MarkdownCompileInfo
        (field "filePath" string)
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
