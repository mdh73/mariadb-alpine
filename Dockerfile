FROM alpine:latest

ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.title="mariadb-alpine" \
  org.opencontainers.image.description="A MariaDB container suitable for development" \
  org.opencontainers.image.license="MIT"

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

RUN \
  #apk update \
  #apk upggrade \
  apk add --no-cache mariadb && \
  TO_KEEP=$(echo " \
    etc/ssl/certs/ca-certificates.crt$ \
    usr/bin/mariadbd$ \
    usr/bin/mariadb$ \
    usr/bin/getconf$ \
    usr/bin/getent$ \
    usr/bin/my_print_defaults$ \
    usr/bin/mariadb-install-db$ \
    usr/share/mariadb/charsets \
    usr/share/mariadb/english \
    usr/share/mariadb/mysql_system_tables.sql$ \
    usr/share/mariadb/mysql_performance_tables.sql$ \
    usr/share/mariadb/mysql_system_tables_data.sql$ \
    usr/share/mariadb/maria_add_gis_sp_bootstrap.sql$ \
    usr/share/mariadb/mysql_sys_schema.sql$ \
    usr/share/mariadb/fill_help_tables.sql$" | \
    tr -d " \t\n\r" | sed -e 's/usr/|usr/g' -e 's/^.//') && \
  INSTALLED=$(apk info -q -L mariadb-common mariadb linux-pam ca-certificates | grep "\S") && \
  for path in $(echo "${INSTALLED}" | grep -v -E "${TO_KEEP}"); do \
    eval rm -rf "${path}"; \
  done && \
  touch /usr/share/mariadb/mysql_test_db.sql && \
  echo "!includedir /etc/my.cnf.d" > /etc/my.cnf && \
  sed -ie 's/127.0.0.1/%/' /usr/share/mariadb/mysql_system_tables_data.sql && \
  mkdir /run/mysqld && \
  chown mysql:mysql /etc/my.cnf.d/ /run/mysqld /usr/share/mariadb/mysql_system_tables_data.sql

COPY sh/resolveip.sh /usr/bin/resolveip
COPY sh/run.sh /run.sh

COPY my.cnf /tmp/my.cnf

HEALTHCHECK --start-period=5s CMD pgrep mariadbd

VOLUME ["/var/lib/mysql"]
ENTRYPOINT ["/run.sh"]
EXPOSE 3306
