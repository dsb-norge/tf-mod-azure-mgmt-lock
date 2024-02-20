#!/usr/bin/env bash

set -euo pipefail # Exit on error, exit on any variable not set, catch errors in piped commands
set -m            # Enable Job Control for parallel execution
# set -x # debug

# causes terraform commands to behave as if the -input=false flag was specified.
export TF_INPUT=0

# non-empty value causes terraform to adjust its output to avoid suggesting specific commands to run next
export TF_IN_AUTOMATION=1

# azurem provider configuration
export ARM_TENANT_ID='goes here'
export ARM_SUBSCRIPTION_ID='goes here'

# first things first
terraform init

getTestFilesArgs() {
  local test_files args
  test_files="$*"
  args=""
  for file in $test_files; do
    args+=" -filter=$file"
  done
  echo "$args"
}
# extra tf args
extraGlobalArgs="" # ex. -chdir=DIR and/or -no-color
extraTestArgs=""   # ex -verbose and possibly -test-directory=path

getSeparator() {
  printf '=%.0s' {1..100}
}

getShortSeparator() {
  printf '=%.0s' {1..60}
}

printSection() {
  echo -e "\n\n${1}\n$(getSeparator)\n"
}

printGreenSubSection() {
  echo -e "\e[32m${1}\e[0m\n$(getShortSeparator)\n"
}

printRedSubSection() {
  echo -e "\e[31m${1}\e[0m\n$(getShortSeparator)\n"
}

printSection "Terraform Init"
terraform init

testsDir="tests"
maxParallelTests=10 # max number of jobs to run in parallel
readarray -t testFilePaths < <(find "$testsDir" -mindepth 1 -maxdepth 1 -type f -name '*.tftest.hcl')
totalNumberOfTests="${#testFilePaths[@]}"

declare -a unitTestFiles=()
declare -a integrationTestFiles=()
declare -a otherTestFiles=()

for testFilePath in "${testFilePaths[@]}"; do
  testFile=$(basename "$testFilePath")
  if [[ $testFile == "unit"* ]]; then
    unitTestFiles+=("$testFilePath")
  elif [[ $testFile == "integration"* ]]; then
    integrationTestFiles+=("$testFilePath")
  else
    otherTestFiles+=("$testFilePath")
  fi
done

printSection "Pre-flight"
echo "Total number of tests: $totalNumberOfTests"
echo "  - unit tests: ${#unitTestFiles[@]}"
echo "  - integration tests: ${#integrationTestFiles[@]}"
echo "  - other tests: ${#otherTestFiles[@]}"
echo "Maximum tests to run in parallel: $maxParallelTests"

enqueueTests() {
  local testFiles testFile testType
  testType="$1"
  shift
  testFiles=("$@")
  for testFile in "${testFiles[@]}"; do
    filesForAllTests["$testNumber"]=$testFile
    testTypesForAllTests["$testNumber"]=$testType
    invocationsForAllTests["$testNumber"]="terraform $extraGlobalArgs test -filter=$testFile $extraTestArgs"
    ((testNumber++)) || :
  done
}

testNumber=0
filesForAllTests=()
invocationsForAllTests=()
testTypesForAllTests=()
enqueueTests "unit test" "${unitTestFiles[@]}"
enqueueTests "integration test" "${integrationTestFiles[@]}"
enqueueTests "uncategorized test" "${otherTestFiles[@]}"

startInBackground() {
  # a way to background a process and suppress the output
  # { "$@" 2>&3 & } 3>&2 2>/dev/null

  # this adds 'bash -c' to spawn a new process
  { bash -c "$@" 2>&3 & } 3>&2 2>/dev/null
}

getRunningTests() {
  readarray -t running < <(jobs -rp) # get running jobs
}

waitForAnyTestToComplete() {
  local exitCode=0
  wait -p testPid -n "${running[@]}" >/dev/null 2>&1 || exitCode=$? # wait for any job to finish
  ((numOfTestsFinished++)) || :                                     # keep track of finished tests count
  exitCodesFromAllTests[$testPid]=$exitCode
  getRunningTests # refresh info about running tests
}

# test jobs save their results here
outputDir=$(mktemp -d)

# information to record about each test
pidsOfAllTests=()
exitCodesFromAllTests=()
outputFilesFromAllTests=()
numOfTestsFinished=0

# run all tests
printSection "Running tests"
for ((testNumber = 0; testNumber < $totalNumberOfTests; testNumber++)); do

  getRunningTests # refresh info about running tests

  # if max number of parallel tests is reached, wait for any job to finish
  while [ ${#running[@]} -ge $maxParallelTests ]; do
    waitForAnyTestToComplete
  done

  # command to run inside a subshell with all output redirected to file
  testInvocation="${invocationsForAllTests[$testNumber]}"
  wrapped_command=$(printf '( %s ) >"%s/$$.txt" 2>&1' "$testInvocation" "$outputDir")

  # debug
  # wrapped_command=$(printf '( %s ) >"%s/$$.txt" 2>&1' "t=$((1 + RANDOM % 5)) ; sleep \$t ; echo \"slept \$t\" " "$outputDir")

  # run in background, supress output from backgrounding the job
  testFile=${filesForAllTests[$testNumber]}
  echo -n "Starting test for file '$testFile' ..."
  startInBackground "$wrapped_command"

  # process id of the backgrounded job
  testPid=$!
  pidsOfAllTests["$testNumber"]=$testPid
  outputFilesFromAllTests["$testNumber"]="$outputDir/$testPid.txt"
  echo "done"
done
echo -e "All tests started.\n"

# wait for all remaining tests to finish
echo -n "Waiting for remaining tests to finish ..."
getRunningTests # refresh info about running tests
while [ $numOfTestsFinished -lt $totalNumberOfTests ]; do
  waitForAnyTestToComplete
done
echo "done"
printSection ""

# overall exit code is the sum of all exit codes
overallExitCode=$(
  IFS=+
  echo "$((${exitCodesFromAllTests[*]}))"
)

# summarize output from all tests
summarizeTests() {
  local testFiles testFile testType
  testFiles=("$@")
  countOfTests="${#testFiles[@]}"
  if [ $countOfTests -le 0 ]; then
    return
  fi
  testType=${testTypesForAllTests["$testNumber"]}
  printSection "Summary of $countOfTests ${testType}s"
  for _ in "${testFiles[@]}"; do
    testFile=${filesForAllTests[$testNumber]}
    testType=${testTypesForAllTests[$testNumber]}
    testInvocation=${invocationsForAllTests[$testNumber]}
    testPid=${pidsOfAllTests[$testNumber]}
    testExitCode=${exitCodesFromAllTests[$testPid]}
    if [ $testExitCode -eq 0 ]; then
      printGreenSubSection "$testFile"
      echo -e "overall result: \e[32msuccess\e[0m" # Green color for success
    else
      printRedSubSection "$testFile"
      echo -e "overall result: \e[31mfailure\e[0m" # Red color for failure
    fi
    echo "invocation: $testInvocation"
    echo "exit code : $testExitCode"
    printf '\noutput from test:\n'
    cat "${outputFilesFromAllTests[$testNumber]}"
    rm "${outputFilesFromAllTests[$testNumber]}" || : >/dev/null 2>&1
    printf '\n\n'
    ((testNumber++)) || :
  done
}

testNumber=0
summarizeTests "${unitTestFiles[@]}"
summarizeTests "${integrationTestFiles[@]}"
summarizeTests "${otherTestFiles[@]}"

printSection ""
echo "Overall exit code: $overallExitCode"

rm -rf "$outputDir" || : >/dev/null 2>&1
