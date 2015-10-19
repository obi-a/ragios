FROM cloudgear/ruby:2.2-onbuild
ENV RAGIOS_COUCHDB_ADDRESS couchdb
ENV RAGIOS_BIND_ADDRESS tcp://0.0.0.0:5041
EXPOSE 5041
CMD ./ragios s start
