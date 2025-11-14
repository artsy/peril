FROM node:16-alpine

WORKDIR /app

# Install system dependencies
# Add deploy user
RUN apk --no-cache --quiet add \
  dumb-init && \
  adduser -D -g '' deploy && \
  mkdir ./api ./dashboard

# Copy files required for installation of application dependencies
COPY package.json yarn.lock ./
COPY api/package.json api/yarn.lock ./api/
COPY dashboard/package.json dashboard/yarn.lock ./dashboard/

# Install application dependencies
RUN yarn global add react-scripts serve && \
  yarn install --frozen-lockfile --ignore-scripts && \
  yarn cache clean

COPY . ./

ENV SKIP_PREFLIGHT_CHECK=true
ENV REACT_APP_PUBLIC_API_ROOT_URL="https://peril-api-staging.artsy.net"
ENV REACT_APP_PUBLIC_WEB_ROOT_URL='https://peril-staging.artsy.net'

# Build application
# Update file/directory permissions
RUN yarn workspace dashboard build && \
  yarn workspace api build || exit 0 && \
  chown -R deploy:deploy ./

# Switch to less-privileged user
USER deploy

ENTRYPOINT ["/usr/bin/dumb-init", "./scripts/load_secrets_and_run.sh"]
CMD ["yarn", "workspace", "api", "start"]
