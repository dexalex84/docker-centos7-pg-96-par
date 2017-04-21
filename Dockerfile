# Docker Postgres Tutorial with pglogocal 

# https://www.andreagrandi.it/2015/02/21/how-to-create-a-docker-image-for-postgresql-and-persist-data/

FROM centos:latest
LABEL maitainer = Burenin Aleksei <dexalex@gmail.com>

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm

RUN yum update -y ; yum -y install postgresql96-server postgresql96-devel postgresql96-contrib ; yum clean all

ENV PATH /usr/pgsql-9.6/bin:/:$PATH
ENV PGDATA /var/lib/pgsql/data
ENV POSTGRESQL_CONF_PATH /var/lib/pgsql/data/postgresql.conf
ENV PG_HBA_CONF_PATH /var/lib/pgsql/data/pg_hba.conf 

ADD ./postgresql-setup /usr/bin/postgresql-setup
ADD ./start_postgres.sh /start_postgres.sh

RUN chmod +x /usr/bin/postgresql-setup
RUN chmod +x /start_postgres.sh

RUN /usr/bin/postgresql-setup initdb

RUN echo configure postgresql.conf to make accessible from outside:
RUN sed -itmp -e 's/#listen_addresses = \x27localhost\x27/listen_addresses = \x27*\x27/g' ${POSTGRESQL_CONF_PATH}

RUN echo configure pg_hba.conf 
RUN echo "host    all             all             all               trust" >> ${PG_HBA_CONF_PATH}

#RUN echo install postgresql96-pglogical
#RUN yum install http://packages.2ndquadrant.com/pglogical/yum-repo-rpms/pglogical-rhel-1.0-2.noarch.rpm -y && \
#     yum install postgresql96-pglogical -y

#RUN echo update postgresql.conf to use logical replication
#RUN sed -i -e 's/#max_wal_senders = 0/max_worker_processes = 10/g' ${POSTGRESQL_CONF_PATH}
#RUN sed -i -e 's/#max_replication_slots = 0/max_replication_slots = 10/g' ${POSTGRESQL_CONF_PATH}
#RUN sed -i -e 's/#wal_level = minimal = 0/wal_level = \x27logical\x27/g' ${POSTGRESQL_CONF_PATH}
#RUN sed -i -e 's/#max_worker_processes = 8/max_worker_processes = 10/g' ${POSTGRESQL_CONF_PATH}
#RUN sed -i -e 's/#shared_preload_libraries = \x27\x27/shared_preload_libraries = \x27pglogical\x27/g' ${POSTGRESQL_CONF_PATH}
#RUN sed -i -e 's/#track_commit_timestamp = off/track_commit_timestamp = on/g' ${POSTGRESQL_CONF_PATH}

#RUN echo enable replication in pg_hba.conf
#RUN echo host       replication     postgres        all                 trust >> ${PG_HBA_CONF_PATH}
#RUN echo local      replication     postgres        all                 trust >> ${PG_HBA_CONF_PATH}

VOLUME ["/var/lib/pgsql"]

EXPOSE 5432

CMD ["/bin/bash", "/start_postgres.sh"]

