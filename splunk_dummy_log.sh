#!/bin/bash
# Paths
SPLUNK_HOME=/opt/splunk
DUMMY_LOG=/var/log/dummy_app.log
# Step 1: Create dummy log file and start writing to it
mkdir -p "$(dirname "$DUMMY_LOG")"
touch "$DUMMY_LOG"
echo "Generating dummy logs into $DUMMY_LOG..."
# Background log writer (you can kill it later)
( while true; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] User login from IP $(shuf -n 1 -i 1-255).$(shuf -n 1 -i 1-255).$(shuf -n 1 -i 1-255).$(shuf -n 1 -i 1-255)" >> "$DUMMY_LOG"
    sleep 1
done ) &
# Step 2: Add Splunk monitor input
"$SPLUNK_HOME/bin/splunk" add monitor "$DUMMY_LOG" -index main -sourcetype dummy_logs -auth admin:$P@ssword
# Step 3: Restart Splunk to apply changes (optional)
"$SPLUNK_HOME/bin/splunk" restart
echo "Splunk is now monitoring dummy log files."
