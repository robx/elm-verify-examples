module VerifyExamples.Elm
    exposing
        ( CompileInfo
        , decodeCompileInfo
        , parseComments
        )

import Json.Decode as Decode exposing (Decoder, Value, field, string)
import VerifyExamples.Comment as Comment exposing (Comment)
import VerifyExamples.ModuleName as ModuleName exposing (ModuleName)
import VerifyExamples.Warning.Ignored as Ignored exposing (Ignored)


type alias CompileInfo =
    { moduleName : ModuleName
    , fileText : String
    , ignoredWarnings : List Ignored
    }


parseComments : String -> List Comment
parseComments =
    -- move that code here
    Comment.parse


decodeCompileInfo : Decoder CompileInfo
decodeCompileInfo =
    Decode.map3 CompileInfo
        (field "moduleName" string
            |> Decode.map ModuleName.fromString
        )
        (field "fileText" string)
        (field "ignoredWarnings" Ignored.decode)
