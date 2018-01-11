module VerifyExamples.Markdown
    exposing
        ( CompileInfo
        , decodeCompileInfo
        , parseComments
        )

import Json.Decode as Decode exposing (Decoder, Value, decodeValue, field, list, string)
import VerifyExamples.Comment as Comment exposing (Comment)
import VerifyExamples.Warning.Ignored as Ignored exposing (Ignored)


type alias CompileInfo =
    { filePath : String
    , fileText : String
    , ignoredWarnings : List Ignored
    }


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
