#!/bin/sh
#
# start_mysqld_and_auto_install.sh - starts an instance of mysqld before
# auto_installing and running do_mysql's test suite. It is inspired by
# debian/test_mysql.sh from libdbi-drivers source package.

set -ex

MYTEMP_DIR=`mktemp -d`

export MYSQL_UNIX_PORT=${MYTEMP_DIR}/mysql.sock
DO_MYSQL_USER=${USER}
DO_MYSQL_PASS=
DO_MYSQL_DBNAME=test
DO_MYSQL_DATABASE=/${DO_MYSQL_DBNAME}

mysqladmin="/usr/bin/mysqladmin --user=${DO_MYSQL_USER} --socket=${MYSQL_UNIX_PORT}"

mysql_install_db --no-defaults --datadir=${MYTEMP_DIR} --force --skip-name-resolve --user=${DO_MYSQL_USER}
cat >${MYTEMP_DIR}/init.sql <<EOT
UPDATE mysql.user SET plugin = "";
FLUSH PRIVILEGES;
EOT
/usr/sbin/mysqld --no-defaults --user=${DO_MYSQL_USER} --socket=${MYSQL_UNIX_PORT} --datadir=${MYTEMP_DIR} --skip-networking --init-file=${MYTEMP_DIR}/init.sql &
MYSQL_PID=$!
echo -n pinging mysqld.
attempts=0
while ! $mysqladmin ping ; do
  sleep 3
  attempts=$((attempts+1))
  if [ ${attempts} -gt 10 ] ; then
    echo "skipping test, mysql server could not be contacted after 30 seconds"
    exit 0
  fi
done

cleanup() {
  $mysqladmin shutdown || kill "${MYSQL_PID}"
  rm -rf ${MYTEMP_DIR}
}
trap cleanup INT EXIT TERM

"$@"
