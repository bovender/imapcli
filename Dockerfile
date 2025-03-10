FROM ruby:3.4-alpine
LABEL maintainer="bovender@bovender.de"
LABEL description="Command-line tool to query IMAP servers, collect stats etc."

WORKDIR /
ADD . /imapcli
RUN apk add --no-cache git build-base && \
  gem update --system && \
  cd imapcli && \
  bundle config set --local without development test && \
  bundle config set --local deployment true && \
  bundle install && \
  apk del build-base && \
  rm -rf /var/cache/apk/*

WORKDIR /imapcli
ENTRYPOINT ["bundle", "exec", "exe/imapcli"]

