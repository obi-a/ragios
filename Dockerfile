FROM ruby:2.4.1-stretch
RUN apt-get update && apt-get install -y \
    libzmq3-dev
ENV RAGIOS_COUCHDB_ADDRESS couchdb
ENV RAGIOS_COUCHDB_PORT 5984
ENV AGIOS_DATABASE ragios_database
ENV RAGIOS_WEB_SERVER_ADDRESS tcp://0.0.0.0:5041
EXPOSE 5041
EXPOSE 5042
EXPOSE 5043
EXPOSE 5044
EXPOSE 5045
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN bundle install
CMD bundle exec rake webapp_tests core_tests
