#!/bin/sh
set -e

envsubst < /web/env.template.js > /web/env.js

# Read /web/env.js and show content
echo "Using environment variables:"
cat /web/env.js

exec "$@"
