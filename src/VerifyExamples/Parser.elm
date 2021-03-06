module VerifyExamples.Parser exposing (Parsed, parse)

import VerifyExamples.Ast.Grouped as GroupedAst exposing (GroupedAst)
import VerifyExamples.Ast.Intermediate as IntermediateAst exposing (IntermediateAst)
import VerifyExamples.Comment as Comment exposing (Comment)
import VerifyExamples.ExposedApi as ExposedApi exposing (ExposedApi)
import VerifyExamples.TestSuite as TestSuite exposing (TestSuite)


type alias Parsed =
    { exposedApi : ExposedApi
    , testSuites : List TestSuite
    }


parse : String -> Parsed
parse value =
    let
        comments =
            value
                |> Comment.parse
    in
    { exposedApi =
        ExposedApi.parse value <|
            List.filterMap Comment.function comments
    , testSuites =
        comments
            |> List.map toTestSuite
    }


toTestSuite : Comment -> TestSuite
toTestSuite comment =
    case comment of
        Comment.FunctionDoc { functionName, comment } ->
            comment
                |> IntermediateAst.fromString
                |> IntermediateAst.toAst
                |> GroupedAst.fromAst
                |> TestSuite.fromAst (Just functionName)

        Comment.ModuleDoc comment ->
            comment
                |> IntermediateAst.fromString
                |> IntermediateAst.toAst
                |> GroupedAst.fromAst
                |> TestSuite.fromAst Nothing
