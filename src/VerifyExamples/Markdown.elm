module VerifyExamples.Markdown
    exposing
        ( CompileInfo
        , decodeCompileInfo
        , moduleName
        , parseComments
        )

import Json.Decode as Decode exposing (Decoder, Value, decodeValue, field, list, string)
import Regex exposing (HowMany(..), Regex)
import Regex.Util exposing (newline)
import VerifyExamples.Comment as Comment exposing (Comment(..))
import VerifyExamples.ModuleName as ModuleName exposing (ModuleName)
import VerifyExamples.Warning.Ignored as Ignored exposing (Ignored)


type alias CompileInfo =
    { filePath : String
    , fileText : String
    , ignoredWarnings : List Ignored
    }


moduleName : String -> ModuleName
moduleName filePath =
    -- TODO: define a module name based on the file path
    -- TODO: make it so specs generated from markdown don't import the source file :-)
    ModuleName.fromString "Basics"


parseComments : String -> List Comment
parseComments =
    Regex.find All commentRegex
        >> List.filterMap (toComment << .submatches)


toComment : List (Maybe String) -> Maybe Comment
toComment matches =
    case matches of
        (Just comment) :: [] ->
            Just (ModuleDoc comment)

        _ ->
            Nothing


commentRegex : Regex
commentRegex =
    Regex.regex <|
        String.concat
            [ "```elm"
            , newline
            , "([^]*?)"
            , newline
            , "```"
            ]


decodeCompileInfo : Decoder CompileInfo
decodeCompileInfo =
    Decode.map3 CompileInfo
        (field "filePath" string)
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
