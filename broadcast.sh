#!/bin/bash

# --- CONFIGURATION ---
CSV_FILE="/home/sangoma/numbers.csv"  # Ensure this is the full path
ANN_ID="1"                            # Your Announcement ID
SLEEP_TIME=5                          # Seconds between calls

# --- THE ENGINE ---
# We read the first three columns: Number, First Name, Last Name
while IFS=, read -r raw_phone first_name last_name rest
do
    # 1. Clean the number: Remove ( ) - and spaces
    CLEAN_NUM=$(echo "$raw_phone" | tr -d '[:space:]-()')

    # 2. Add the '1' prefix if it's a 10-digit number
    if [ ${#CLEAN_NUM} -eq 10 ]; then
        CLEAN_NUM="1$CLEAN_NUM"
    fi

    # 3. Skip the line if the number is empty or too short
    if [ ${#CLEAN_NUM} -lt 11 ]; then
        echo "Skipping invalid entry: $first_name $last_name ($raw_phone)"
        continue
    fi

    echo "Calling $first_name $last_name at $CLEAN_NUM..."

    # 4. Create the Call File
    cat <<EOF > /tmp/$CLEAN_NUM.call
Channel: local/$CLEAN_NUM@from-internal
MaxRetries: 2
RetryTime: 60
WaitTime: 30
Context: app-announcement-$ANN_ID
Extension: s
Priority: 1
Set: CALLERID(num)=8624452644
EOF

    # 5. Fix permissions and move to Asterisk
    chown asterisk:asterisk /tmp/$CLEAN_NUM.call
    mv /tmp/$CLEAN_NUM.call /var/spool/asterisk/outgoing/

    sleep $SLEEP_TIME

done < "$CSV_FILE"

echo "Broadcast complete."