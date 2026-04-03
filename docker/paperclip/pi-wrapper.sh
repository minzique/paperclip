#!/bin/sh
# Wrapper around pi that sources fresh Claude OAuth token before each invocation.
# Set PAPERCLIP_PI_COMMAND=pi-wrapper to use this.

if [ -f /run/claude-token/env ]; then
  export $(cat /run/claude-token/env | xargs)
fi

exec pi "$@"
