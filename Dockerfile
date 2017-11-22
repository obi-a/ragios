FROM ruby:2.4.1-stretch
RUN apt-get update && apt-get install -y \
    libzmq3-dev
ENV RAGIOS_COUCHDB_ADDRESS couchdb
ENV RAGIOS_COUCHDB_PORT 5984
ENV RAGIOS_DATABASE ragios_database
COPY . /usr/src/ragios
WORKDIR /usr/src/ragios
RUN bundle install
CMD bundle exec rake webapp_tests core_tests
