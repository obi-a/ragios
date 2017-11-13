FROM ruby:2.4.1-stretch
RUN apt-get update && apt-get install -y \
    libzmq3-dev

COPY . /usr/src/app
WORKDIR /usr/src/app
RUN bundle install
