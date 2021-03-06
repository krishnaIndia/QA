# Exit the script if building fails
$ErrorActionPreference = "Stop"

cd $env:APPVEYOR_BUILD_FOLDER

# Prepare test script
$cargo_test = {
    # Check cargo has installed properly
    cargo -V
    if (!$?) {
        99 > ($env:TEMP + "\TestResult.txt")
        return
    }

    cd $env:APPVEYOR_BUILD_FOLDER

    # Use features if they've been set
    if ($env:Features) {
        $with_features = "--features",$env:Features
    }

    # Use Release flag if required
    if ($env:CONFIGURATION -eq "Release") {
        $release_flag = "--release"
    }

    cargo test $with_features $release_flag -- --nocapture
    $LASTEXITCODE > ($env:TEMP + "\TestResult.txt")
}

# Run the test script
""
"Starting tests."
$job = Start-Job -ScriptBlock $cargo_test

# Set timeout to env var or use default of 10 minutes
$timeout_ms = 600000
if ($env:TimeoutSeconds) {
    $timeout_ms = [Int32]$env:TimeoutSeconds * 1000
}

# Loop until timed out or tests have completed
$ErrorActionPreference = "Continue"
$start_time = Get-Date
$current_time = $start_time
$completed = $false
while ((($current_time - $start_time).TotalMilliseconds -lt $timeout_ms) -and (-not $completed)) {
    $sleep_ms = 100
    Start-Sleep -m $sleep_ms

    # Display test's results so far
    Receive-Job $job

    # Check if the tests have completed
    $running = $job | Where-Object { $_.State -match 'running' }
    if (-not $running) {
        $completed = $true
    }
    $current_time = Get-Date
}

if (-not $completed) {
    # Exit with non-zero value if the test timed out

    # Kill job and retrieve and buffered output
    Get-ChildItem "target\$env:CONFIGURATION" -Filter *.exe | Foreach-Object { Stop-Process -name $_.BaseName *>$null }
    Stop-Job $job
    Receive-Job $job

    $timeout_seconds = $timeout_ms / 1000
    ""
    "Tests ran for longer than $timeout_seconds seconds, so have timed out."
    $test_result = -2
} else {
    # Retrieve the return code of the test command, so we can return it later
    $test_result = Get-Content ($env:TEMP + "\TestResult.txt")
}

# Run Clippy, but don't fail overall if Clippy fails.
# ""
# "Running Clippy."
# multirust run nightly cargo test --no-run --features clippy

exit $test_result
