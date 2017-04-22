#!/bin/bash

INST_PGLOGICAL=${INST_PGLOGICAL:-}

POSTGRESQL_CONF_PATH=/var/lib/pgsql/data/postgresql.conf
PG_HBA_CONF_PATH=/var/lib/pgsql/data/pg_hba.conf

DB_NAME=${POSTGRES_DB:-}
DB_USER=${POSTGRES_USER:-}
DB_PASS=${POSTGRES_PASSWORD:-}
PG_CONFDIR="/var/lib/pgsql/data"

__create_user() {
  #Grant rights

  #echo create user params:
  #echo $DB_NAME
  #echo $DB_USER
  #echo $DB_PASS

  usermod -G wheel postgres

  # Check to see if we have pre-defined credentials to use
if [ -n "${DB_USER}" ]; then
  if [ -z "${DB_PASS}" ]; then
    echo ""
    echo "WARNING: "
    echo "No password specified for \"${DB_USER}\". Generating one"
    echo ""
    DB_PASS=$(pwgen -c -n -1 12)
    echo "Password for \"${DB_USER}\" created as: \"${DB_PASS}\""
  fi
    echo "Creating user \"${DB_USER}\"..."
    echo "CREATE ROLE ${DB_USER} with CREATEROLE login superuser PASSWORD '${DB_PASS}';" |
      sudo -u postgres -H postgres --single \
       -c config_file=${PG_CONFDIR}/postgresql.conf -D ${PG_CONFDIR}
  
fi

if [ -n "${DB_NAME}" ]; then
  echo "Creating database \"${DB_NAME}\"..."
  echo "CREATE DATABASE ${DB_NAME};" | \
    sudo -u postgres -H postgres --single \
     -c config_file=${PG_CONFDIR}/postgresql.conf -D ${PG_CONFDIR}

  if [ -n "${DB_USER}" ]; then
    echo "Granting access to database \"${DB_NAME}\" for user \"${DB_USER}\"..."
    echo "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} to ${DB_USER};" |
      sudo -u postgres -H postgres --single \
      -c config_file=${PG_CONFDIR}/postgresql.conf -D ${PG_CONFDIR}
  fi
fi
}


__inst_pglogical() {

 echo install postgresql96-pglogical
 yum install http://packages.2ndquadrant.com/pglogical/yum-repo-rpms/pglogical-rhel-1.0-2.noarch.rpm -y && \
     yum install postgresql96-pglogical -y

 echo update postgresql.conf to use logical replication
 sed -i -e 's/#max_wal_senders = 0/max_worker_processes = 10/g' ${POSTGRESQL_CONF_PATH}
 sed -i -e 's/#max_replication_slots = 0/max_replication_slots = 10/g' ${POSTGRESQL_CONF_PATH}
 sed -i -e 's/#wal_level = minimal/wal_level = logical/g' ${POSTGRESQL_CONF_PATH}
 sed -i -e 's/#max_worker_processes = 8/max_worker_processes = 10/g' ${POSTGRESQL_CONF_PATH}
 sed -i -e 's/#shared_preload_libraries = \x27\x27/shared_preload_libraries = \x27pglogical\x27/g' ${POSTGRESQL_CONF_PATH}
 sed -i -e 's/#track_commit_timestamp = off/track_commit_timestamp = on/g' ${POSTGRESQL_CONF_PATH}

 echo #set params to pglogical replication plugin >>  ${POSTGRESQL_CONF_PATH}
 echo max_wal_senders = 10 >>  ${POSTGRESQL_CONF_PATH}

 echo enable replication in pg_hba.conf
 echo local   replication     postgres                                trust >> ${PG_HBA_CONF_PATH}
 echo host    replication     postgres        127.0.0.1/32            trust >> ${PG_HBA_CONF_PATH}
 echo host    replication     postgres        ::1/128                 trust >> ${PG_HBA_CONF_PATH}
 echo host    replication     postgres        samenet                 trust >> ${PG_HBA_CONF_PATH}


}

__run (){

 echo run server:
 su postgres -c '/usr/pgsql-9.6/bin/postgres -D /var/lib/pgsql/data > /var/lib/pgsql/data/server.log 2>&1 &' 
 tail -f /var/lib/pgsql/data/server.log

 echo see logs /var/lib/pgsql/data/pg_log/* also

}

# Call all functions

 __create_user
  
 if [ -n "${INST_PGLOGICAL}" ]; then
  __inst_pglogical
 fi

 __run

 
 

