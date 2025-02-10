#Script to rip a DVD chapter by chapter using handbreak CLI.  




# Set the HandBrakeCLI path
$HANDBRAKE_CLI = "C:\HandBrake\HandBrakeCLI.exe"

# Set the DVD drive letter (adjust accordingly, e.g., D: or E:)
$DVD_DRIVE = "E:\"

# Set the output directory
$OUTPUT_DIR = "$HOME\Videos\DVD_Rip"
New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null

# Set log file path
$LOG_FILE = "$OUTPUT_DIR\rip_dvd.log"

# Start logging
"DVD Ripping Started: $(Get-Date)" | Out-File -FilePath $LOG_FILE -Append
"Scanning DVD for titles..." | Tee-Object -FilePath $LOG_FILE -Append

# Scan the DVD for titles
$titles_output = & $HANDBRAKE_CLI -i $DVD_DRIVE --scan 2>&1

# Save scan output to log for debugging
$titles_output | Out-File -FilePath $LOG_FILE -Append

# Extract available titles correctly
$titles = $titles_output | Select-String -Pattern "scan: DVD has (\d+) title\(s\)" | ForEach-Object { $_.Matches.Groups[1].Value }

if (-not $titles) {
    Write-Host "No titles detected!" | Tee-Object -FilePath $LOG_FILE -Append
    exit
}

$titles = 1..$titles  # Create a range of title numbers (1 to max title count)

foreach ($TITLE in $titles) {
    # Extract chapter count for the title
	$chapters_output = & $HANDBRAKE_CLI -i $DVD_DRIVE -t $TITLE --scan 2>&1
	$chapters_output | Out-File -FilePath $LOG_FILE -Append
    #$title_pattern = "scan: scanning title $TITLE"
	$chapter_matches = $chapters_output | Select-String -Pattern "^\s+\+ (\d+): duration"

    if ($chapter_matches) {
        $TOTAL_CHAPTERS = ($chapter_matches | Measure-Object).Count
    } else {
        $TOTAL_CHAPTERS = 0
    }

    $logMessage = "Processing Title $TITLE with $TOTAL_CHAPTERS chapters..."
    Write-Host $logMessage
    $logMessage | Out-File -FilePath $LOG_FILE -Append

    # Loop through each chapter
    for ($CHAPTER = 1; $CHAPTER -le $TOTAL_CHAPTERS; $CHAPTER++) {
        $OUTPUT_FILE = "$OUTPUT_DIR\title${TITLE}_chapter${CHAPTER}.mp4"

        $logMessage = "Ripping Title $TITLE, Chapter $CHAPTER..."
        Write-Host $logMessage
        $logMessage | Out-File -FilePath $LOG_FILE -Append

        & $HANDBRAKE_CLI -i $DVD_DRIVE -t $TITLE -c $CHAPTER -o $OUTPUT_FILE -e x264 -q 20 -B 160 --optimize | Tee-Object -FilePath $LOG_FILE -Append
    }
}

# Final log entry
"DVD Ripping Completed: $(Get-Date)" | Tee-Object -FilePath $LOG_FILE -Append
Write-Host "DVD ripping completed! Files saved in $OUTPUT_DIR. Log saved to $LOG_FILE"
