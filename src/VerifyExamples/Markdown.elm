module VerifyExamples.Markdown
    exposing
        ( CompileInfo
        , decodeCompileInfo
        , parse
        )

import Json.Decode as Decode exposing (Decoder, Value, decodeValue, field, list, string)
import VerifyExamples.ModuleName as ModuleName exposing (ModuleName)
import VerifyExamples.Parser as Parser exposing (Parsed)
import VerifyExamples.Warning.Ignored as Ignored exposing (Ignored)


type alias CompileInfo =
    { filePath : String
    , fileText : String
    , ignoredWarnings : List Ignored
    }


parse : CompileInfo -> Parsed
parse { fileText } =
    -- FIXME
    Parser.parse fileText


decodeCompileInfo : Decoder CompileInfo
decodeCompileInfo =
    Decode.map3 CompileInfo
        (field "filePath" string)
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
