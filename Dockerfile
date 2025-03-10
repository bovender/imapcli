FROM ruby:alpine
LABEL maintainer="bovender@bovender.de"
LABEL description="Command-line tool to query IMAP servers, collect stats etc."

WORKDIR /
ADD . /imapcli
RUN apk add --no-cache git build-base && \
  gem update --system && \
  cd imapcli && \
  # bundle config set --local without development test && \
  bundle install && \
  apk del build-base && \
  rm -rf /var/cache/apk/*

WORKDIR /imapcli
ENTRYPOINT ["exe/imapcli"]

