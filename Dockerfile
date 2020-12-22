FROM node:12-alpine

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
  yarn install --frozen-lockfile && \
  yarn cache clean

COPY . ./

ENV SKIP_PREFLIGHT_CHECK=true

# Build application
# Update file/directory permissions
RUN yarn workspace dashboard build && \
  chown -R deploy:deploy ./

# Switch to less-privileged user
USER deploy

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["yarn", "workspace", "api", "start"]
