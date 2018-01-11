module VerifyExamples.Comment exposing (Comment(..), function)


type Comment
    = FunctionDoc { functionName : String, comment : String }
    | ModuleDoc String


function : Comment -> Maybe String
function comment =
    case comment of
        FunctionDoc { functionName } ->
            Just functionName

        ModuleDoc _ ->
            Nothing
