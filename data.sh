#!/bin/bash

MODEL="gemini-2.5-flash"
LOG_FILE="ai_assistant.log"

if [ -z "$GEMINI_API_KEY" ]; then
    echo "GEMINI_API_KEY not set"
    echo "Run: export GEMINI_API_KEY=your_api_key"
    exit 1
fi

echo "=================================="
echo "        AI Terminal Assistant"
echo "=================================="
echo "Type 'exit' to quit"
echo ""

echo "SESSION START: $(date)" >> $LOG_FILE

while true
do

read -p "You: " USER_INPUT

if [[ "$USER_INPUT" == "exit" ]]; then
    echo "SESSION END: $(date)" >> $LOG_FILE
    exit
fi

echo "[USER] $(date): $USER_INPUT" >> $LOG_FILE


RESPONSE=$(curl -s \
-H "Content-Type: application/json" \
"https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$GEMINI_API_KEY" \
-d "{
\"contents\": [{
\"parts\": [{
\"text\": \"$USER_INPUT\"
}]
}]
}")


TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [[ -z "$TEXT" ]]; then
    echo "AI response error."
    echo "$RESPONSE"
    continue
fi


echo "[AI RESPONSE] $(date): $TEXT" >> $LOG_FILE


# Detect if output looks like commands
if echo "$TEXT" | grep -E '(^sudo |^apt |^mkdir |^rm |^cd |^touch |^wget |^curl |^git |^npm |^pip)' > /dev/null
then

    echo ""
    echo "AI Suggested Commands:"
    echo "----------------------"
    echo "$TEXT"
    echo "----------------------"

    read -p "Execute? (y/n): " CONFIRM

    if [[ "$CONFIRM" == "y" ]]; then

        echo "$TEXT" | while read -r cmd
        do
            if [[ -n "$cmd" ]]; then
                echo "Running: $cmd"
                echo "[EXECUTING] $cmd" >> $LOG_FILE
                bash -c "$cmd" >> $LOG_FILE 2>&1
            fi
        done

        echo "Task completed."

    else
        echo "Execution cancelled."
    fi

else

    echo ""
    echo "AI:"
    echo "$TEXT"

fi

echo ""

done
