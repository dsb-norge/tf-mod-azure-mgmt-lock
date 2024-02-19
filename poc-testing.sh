#!/usr/bin/env bash

set -euo pipefail

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

getSeparator() {
  printf '=%.0s' {1..100}
}

printSection() {
  echo -e "\n\e[32m${1}\e[0m\n$(getSeparator)\n"
}

test_files=$(find tests -maxdepth 1 -type f -name '*.tftest.hcl')

declare -a unit_test_files_args=()
declare -a integration_test_files_args=()
declare -a other_test_files_args=()

for file in $test_files; do
  if [[ $file == *"unit"* ]]; then
    unit_test_files_args+="-filter=$file "
  elif [[ $file == *"integration"* ]]; then
    integration_test_files_args+="-filter=$file "
  else
    other_test_files_args+="-filter=$file "
  fi
done

# run tests serially
# ========================================

# printSection "Unit Tests"
# for filter_arg in $unit_test_files_args; do
#   terraform test $filter_arg
# done

# printSection "Integration Tests"
# for filter_arg in $integration_test_files_args; do
#   terraform test $filter_arg
# done

# printSection "Other Tests"
# for filter_arg in $other_test_files_args; do
#   terraform test $filter_arg
# done

# debug
# terraform test -filter=tests/integration-tests.tftest.hcl

# run tests in parallel
# ========================================

set -m     # Enable Job Control for parallel execution
maxJobs=10 # max number of jobs to run in parallel

testInvocations=()

for filter_arg in ${unit_test_files_args[@]}; do
  testInvocations+=("terraform test $filter_arg")
done
for filter_arg in ${integration_test_files_args[@]}; do
  testInvocations+=("terraform test $filter_arg")
done
for filter_arg in ${other_test_files_args[@]}; do
  testInvocations+=("terraform test $filter_arg")
done

silent_sub_process() {
  # a way to background a process and suppress the output
  # { "$@" 2>&3 & } 3>&2 2>/dev/null

  # this adds 'bash -c' to spawn a new process
  { bash -c "$@" 2>&3 & } 3>&2 2>/dev/null
}

numTests="${#testInvocations[@]}"

# jobs save results here
outputDir=$(mktemp -d)

updateRunningJobs() {
  readarray -t running < <(jobs -rp) # get running jobs
}

waitForAnyJob() {
  local exitCode=0
  wait -p jobPid -n "${running[@]}" >/dev/null 2>&1 || exitCode=$? # wait for any job to finish
  # echo "jobPid: $jobPid, exitCode: $exitCode"
  jobsDone=$(($jobsDone + 1))
  # echo "jobsDone: $jobsDone"
  pidExitCodes[$jobPid]=$exitCode
  echo -n "."
}

echo "Number of tests: $numTests, running max $maxJobs in parallel"
pids=()
pidExitCodes=()
outFiles=()
jobsDone=0
for ((i = 0; i < $numTests; i++)); do
  testInvocation="${testInvocations[$i]}"
  updateRunningJobs
  while [ ${#running[@]} -ge $maxJobs ]; do # wait for a job-slot
    waitForAnyJob
    updateRunningJobs
  done

  # command to run inside a subshell with all output redirected to file
  wrapped_command=$(printf '( %s ) >"%s/$$.txt" 2>&1' "$testInvocation" "$outputDir")
  silent_sub_process "$wrapped_command" # run in background, supress output from backgrounding the job
  pids[$i]=$!
  outFiles[$i]="$outputDir/$!.txt"
done

# wait for remaining jobs to finish
updateRunningJobs
while [ $jobsDone -lt $numTests ]; do # wait for all jobs to finish
  waitForAnyJob
  updateRunningJobs
done

# determine overall exit code
overallExitCode=$(
  IFS=+
  echo "$((${pidExitCodes[*]}))"
)

# summarize output
for ((i = 0; i < $numTests; i++)); do
  printSection "${testInvocations[$i]}"
  # echo "pid: ${pids[$i]}"
  # echo "exit code: ${pidExitCodes[${pids[$i]}]}"
  # echo "output:"
  cat "${outFiles[$i]}"
  rm "${outFiles[$i]}" || : >/dev/null 2>&1
done

echo ""
printSection ""
echo "Overall exit code: $overallExitCode"

rm -rf "$outputDir" || : >/dev/null 2>&1
