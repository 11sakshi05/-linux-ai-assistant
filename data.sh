#!/bin/bash

API_KEY=$GEMINI_API_KEY
LOGFILE="ai_assistant.log"

if [ -z "$API_KEY" ]; then
  echo "❌ Please set GEMINI_API_KEY"
  exit 1
fi

touch $LOGFILE

echo "====================================="
echo "🤖 Linux AI Assistant Started"
echo "📜 Logging Enabled"
echo "☁ GitHub Backup Enabled"
echo "Type 'exit' to quit"
echo "====================================="

backup_logs() {

git add assistant.log
git commit -m "Log update $(date)"
git push origin main

}

while true
do
    echo ""
    read -p "🧑 You: " PROMPT

    if [[ "$PROMPT" == "exit" ]]; then
        echo "👋 Goodbye!"
        echo "$(date) | USER EXIT" >> $LOGFILE
        backup_logs
        break
    fi

    echo "🤖 Thinking..."

RESPONSE=$(curl -s \
-H "Content-Type: application/json" \
-X POST \
"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
-d "{
\"contents\": [{
\"parts\": [{
\"text\": \"You are a Linux assistant. Respond in JSON {\\\"message\\\":\\\"text\\\",\\\"command\\\":\\\"linux command or empty\\\"}. User request: $PROMPT\"
}]
}]
}")

RAW=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

CLEAN=$(echo "$RAW" | sed 's/```json//g' | sed 's/```//g')

MESSAGE=$(echo "$CLEAN" | jq -r '.message' 2>/dev/null)
COMMAND=$(echo "$CLEAN" | jq -r '.command' 2>/dev/null)

echo ""
echo "🤖 Assistant: $MESSAGE"

echo "$(date) | USER: $PROMPT" >> $LOGFILE
echo "$(date) | ASSISTANT: $MESSAGE" >> $LOGFILE

if [[ -n "$COMMAND" && "$COMMAND" != "null" ]]; then

    if [[ "$COMMAND" == *"rm -rf"* || "$COMMAND" == *"shutdown"* ]]; then
        echo "⚠ Dangerous command blocked"
        echo "$(date) | BLOCKED COMMAND: $COMMAND" >> $LOGFILE
        continue
    fi

    echo ""
    echo "⚡ Running: $COMMAND"

    OUTPUT=$(eval "$COMMAND" 2>&1)

    echo "$OUTPUT"

    echo "$(date) | CMD: $COMMAND" >> $LOGFILE
    echo "$(date) | OUTPUT: $OUTPUT" >> $LOGFILE
    echo "--------------------------------------" >> $LOGFILE

    backup_logs

fi

done


