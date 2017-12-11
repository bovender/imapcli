FROM ruby:alpine
LABEL maintainer=bovender@bovender.de
LABEL description="Command-line tool to query IMAP servers."
RUN apk add --no-cache build-base && \
  gem install --no-rdoc --no-ri imapcli && \
  apk del build-base

ENTRYPOINT ["imapcli"]
