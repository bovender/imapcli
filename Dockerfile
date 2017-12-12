FROM ruby:alpine
LABEL maintainer=bovender@bovender.de
LABEL description="Command-line tool to query IMAP servers."

WORKDIR /
RUN apk add --no-cache git build-base && \
  git clone --depth 1 https://github.com/bovender/imapcli && \
  cd imapcli && \
  bundle && \
  apk del build-base && \
  rm -rf /var/cache/apk/*

WORKDIR /imapcli
ENTRYPOINT ["bundle", "exec", "imapcli"]
