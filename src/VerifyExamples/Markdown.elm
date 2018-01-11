module VerifyExamples.Markdown
    exposing
        ( CompileInfo
        , decodeCompileInfo
        , moduleName
        , parseComments
        )

import Json.Decode as Decode exposing (Decoder, Value, decodeValue, field, list, string)
import VerifyExamples.Comment as Comment exposing (Comment)
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
    -- TODO
    always []


decodeCompileInfo : Decoder CompileInfo
decodeCompileInfo =
    Decode.map3 CompileInfo
        (field "filePath" string)
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
