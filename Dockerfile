FROM ruby:alpine
MAINTAINER bovender@bovender.de
RUN gem install --no-rdoc --no-ri imapcli
ENTRYPOINT ["imapcli"]
