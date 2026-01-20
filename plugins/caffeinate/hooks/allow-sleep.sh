#!/bin/bash

# Re-enable Mac sleep by killing the caffeinate process and cleanup the PID file

PID_FILE="/tmp/claude_caffeinate.pid"

if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null
    rm -f "$PID_FILE"
fi
