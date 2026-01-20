#!/bin/bash

# Prevent Mac from sleeping while Claude Code is running (for up to 1 hour)
# Kill any previously running caffeinate process started by this script

PID_FILE="/tmp/claude_caffeinate.pid"

if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if ps -p "$old_pid" > /dev/null 2>&1; then
        # Ensure the process is caffeinate (full command line check)
        if ps -p "$old_pid" -o args= | grep -q '^caffeinate'; then
            kill "$old_pid" 2>/dev/null
        fi
    fi
    rm -f "$PID_FILE"
fi

nohup caffeinate -i -t 3600 > /dev/null 2>&1 &
echo $! > "$PID_FILE"
