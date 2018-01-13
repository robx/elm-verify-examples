module VerifyExamples.Elm
    exposing
        ( CompileInfo
        , decodeCompileInfo
        , parseComments
        )

import Json.Decode as Decode exposing (Decoder, Value, field, string)
import Regex exposing (HowMany(..), Regex)
import Regex.Util exposing (newline)
import VerifyExamples.Comment as Comment exposing (Comment(..))
import VerifyExamples.ModuleName as ModuleName exposing (ModuleName)
import VerifyExamples.Warning.Ignored as Ignored exposing (Ignored)


type alias CompileInfo =
    { moduleName : ModuleName
    , fileText : String
    , ignoredWarnings : List Ignored
    }


parseComments : String -> List Comment
parseComments =
    Regex.find All commentRegex
        >> List.filterMap (toComment << .submatches)


toComment : List (Maybe String) -> Maybe Comment
toComment matches =
    case matches of
        (Just comment) :: _ :: Nothing :: _ ->
            Just (ModuleDoc comment)

        (Just comment) :: _ :: (Just functionName) :: _ ->
            Just (FunctionDoc { functionName = functionName, comment = comment })

        _ ->
            Nothing


commentRegex : Regex
commentRegex =
    Regex.regex <|
        String.concat
            [ "{-([^]*?)-}" -- anything between comments
            , newline
            , "("
            , "([^\\s(" ++ newline ++ ")]+)" -- anything that is not a space or newline
            , "\\s[:=]" -- until ` :` or ` =`
            , ")?" -- it's possible that we have examples in comment not attached to a function
            ]


decodeCompileInfo : Decoder CompileInfo
decodeCompileInfo =
    Decode.map3 CompileInfo
        (field "moduleName" string
            |> Decode.map ModuleName.fromString
        )
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
