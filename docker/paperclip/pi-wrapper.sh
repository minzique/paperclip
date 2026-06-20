#!/bin/sh
# Wrapper around pi that sources a fresh Claude OAuth token before each invocation.
# Set Paperclip agent command to `pi-wrapper` to use this.

if [ -f /run/claude-token/env ]; then
  # shellcheck disable=SC2046
  export $(cat /run/claude-token/env | xargs)
fi

exec pi "$@"
