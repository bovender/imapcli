FROM ruby:4 AS builder
WORKDIR /imapcli
COPY Gemfile Gemfile.lock imapcli.gemspec .
COPY lib/imapcli/version.rb lib/imapcli/version.rb
RUN apt-get update -qq && \
  apt-get install -y build-essential libc6 && \
  gem update --system && \
  bundle config set --local without development test && \
  bundle config set --local deployment true && \
  bundle install

FROM ruby:4-slim
LABEL maintainer="bovender@bovender.de"
LABEL description="Command-line tool to query IMAP servers, collect stats etc."
WORKDIR /imapcli
RUN apt-get update -qq && \
  apt-get install -y git && \
  apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /imapcli/vendor /imapcli/vendor
COPY . .
ENTRYPOINT ["bundle", "exec", "exe/imapcli"]
