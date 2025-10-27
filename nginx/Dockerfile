FROM nginx:alpine

# Install envsubst (gettext package)
RUN apk add --no-cache gettext

# Copy the template
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template

# The command will be overridden in docker-compose.yml