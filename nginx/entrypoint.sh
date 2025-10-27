#!/bin/bash
# entrypoint.sh - processes template and starts Nginx

# Substitute environment variables into template
envsubst '${ACTIVE_POOL}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf

# Start Nginx in foreground
nginx -g 'daemon off;'
