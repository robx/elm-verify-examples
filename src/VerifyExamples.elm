port module VerifyExamples exposing (..)

import Cmd.Util as Cmd
import Json.Decode as Decode exposing (Decoder, Value, decodeValue, field, list, string)
import Platform
import VerifyExamples.Compiler as Compiler
import VerifyExamples.Elm as Elm
import VerifyExamples.Markdown as Markdown
import VerifyExamples.ModuleName as ModuleName exposing (ModuleName)
import VerifyExamples.Parser as Parser
import VerifyExamples.Warning as Warning exposing (Warning)


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
    | CompileElm Elm.CompileInfo
    | CompileMarkdown Markdown.CompileInfo


update : Msg -> Cmd Msg
update msg =
    case msg of
        ReadElm test ->
            readElm test

        ReadMarkdown test ->
            readMarkdown test

        CompileElm info ->
            info
                |> compileModule
                |> sendResult (ModuleName.toString info.moduleName)

        CompileMarkdown info ->
            info
                |> compileMarkdown
                |> sendResult info.filePath


compileModule : Elm.CompileInfo -> ( List Warning, List ( ModuleName, String ) )
compileModule compileInfo =
    let
        parsed =
            Parser.parse Elm.parseComments compileInfo.fileText
    in
    ( Warning.warnings compileInfo.ignoredWarnings parsed
    , List.concatMap (Compiler.compileElm compileInfo) parsed.testSuites
    )


compileMarkdown : Markdown.CompileInfo -> ( List Warning, List ( ModuleName, String ) )
compileMarkdown compileInfo =
    let
        parsed =
            Parser.parse Markdown.parseComments compileInfo.fileText
    in
    ( Warning.warnings compileInfo.ignoredWarnings parsed
    , List.concatMap (Compiler.compileMarkdown compileInfo) parsed.testSuites
    )


sendResult : String -> ( List Warning, List ( ModuleName, String ) ) -> Cmd msg
sendResult sourceName ( warnings, compiled ) =
    Cmd.batch
        [ compiled
            |> List.map (Tuple.mapFirst ModuleName.toString)
            |> writeFiles
        , warnings
            |> List.map Warning.toString
            |> curry warn sourceName
        ]



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
        [ generateModuleVerifyExamples (runDecoder Elm.decodeCompileInfo >> CompileElm)
        , generateMarkdownVerifyExamples (runDecoder Markdown.decodeCompileInfo >> CompileMarkdown)
        ]


runDecoder : Decoder a -> Value -> a
runDecoder decoder value =
    case decodeValue decoder value of
        Ok info ->
            info

        Err err ->
            Debug.crash "TODO"
