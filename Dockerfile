FROM postgres:14-alpine
COPY config-primary.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/config-primary.sh