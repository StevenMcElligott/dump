#!/bin/bash

# --- CONFIGURATION ---
CSV_FILE="numbers.csv"
ANN_ID="1"      # Change this to your Announcement ID
SLEEP_TIME=5    # Seconds between triggering each call (to avoid VoIP.ms limits)

# --- THE ENGINE ---
while IFS=, read -r name number
do
    # Remove any spaces or dashes from the number
    CLEAN_NUM=$(echo $number | tr -d '[:space:]-()')
    
    echo "Creating call for $name ($CLEAN_NUM)..."

    # Create a temporary call file
    cat <<EOF > /tmp/$CLEAN_NUM.call
Channel: local/$CLEAN_NUM@from-internal
MaxRetries: 2
RetryTime: 60
WaitTime: 30
Context: app-announcement-$ANN_ID
Extension: s
Priority: 1
EOF

    # Fix permissions so Asterisk can read it
    chown asterisk:asterisk /tmp/$CLEAN_NUM.call

    # Move to the outgoing folder (moving is safer than copying)
    mv /tmp/$CLEAN_NUM.call /var/spool/asterisk/outgoing/

    # Wait a bit before the next one so you don't flood your trunk
    sleep $SLEEP_TIME

done < "$CSV_FILE"

echo "All calls triggered."