FROM ruby:2.6.3-alpine

ARG BUNDLE_GITHUB__COM
ENV PORT 8080
EXPOSE 8080
WORKDIR /app

RUN apk --no-cache add \
      bash \
      build-base \
      chromium \
      chromium-chromedriver \
      dumb-init \
      git \
      nginx \
      nodejs \
      tzdata \
      yarn

ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

# Copy system files
COPY docker/files /

# Setup nginx
RUN adduser -u 1000 -D -H -G www-data www-data && \
    mkdir -p /shared/sockets && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4

COPY package.json yarn.lock ./
RUN yarn install

COPY . /app

RUN bundle exec rake assets:precompile

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["script/server.sh"]
