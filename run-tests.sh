#! /bin/bash -ex
TEST_COUNT=18

elm-make src/VerifyExamples.elm --output bin/elm.js --warn
pushd example
../bin/cli.js 2>&1 | tee ../result.json
popd
cat result.json | grep "Passed:   ${TEST_COUNT}"
cat result.json | grep "Failed:   0"
