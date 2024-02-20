#!/usr/bin/env bash

set -euo pipefail # Exit on error, exit on any variable not set, catch errors in piped commands
set -m            # Enable Job Control for parallel execution

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

maxParallelTests=10 # max number of jobs to run in parallel
totalNumberOfTests=30

printSection "Pre-flight"
echo "Total number of tests: $totalNumberOfTests"
echo "Maximum tests to run in parallel: $maxParallelTests"

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

  # debug
  wrapped_command=$(printf '( %s ) >"%s/$$.txt" 2>&1' "t=$((1 + RANDOM % 5)) ; c=$((RANDOM % 2)) ; sleep \$t ; echo \"slept \$t\" ; echo \"exit with \$c\" ; exit \$c ; " "$outputDir")

  # run in background, supress output from backgrounding the job
  echo -n "Starting test # $testNumber ..."
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
for ((testNumber = 0; testNumber < $totalNumberOfTests; testNumber++)); do
  testPid=${pidsOfAllTests[$testNumber]}
  testExitCode=${exitCodesFromAllTests[$testPid]}
  if [ $testExitCode -eq 0 ]; then
    printGreenSubSection "test # $testNumber"
    echo -e "overall result: \e[32msuccess\e[0m" # Green color for success
  else
    printRedSubSection "test # $testNumber"
    echo -e "overall result: \e[31mfailure\e[0m" # Red color for failure
  fi
  echo "exit code : $testExitCode"
  printf '\noutput from test:\n'
  cat "${outputFilesFromAllTests[$testNumber]}"
  rm "${outputFilesFromAllTests[$testNumber]}" || : >/dev/null 2>&1
  printf '\n\n'
done

printSection ""
echo "Overall exit code: $overallExitCode"

rm -rf "$outputDir" || : >/dev/null 2>&1
