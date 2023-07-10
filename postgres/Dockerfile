# Debian 11 (bullseye) has glibc 2.31.
# Debian 12 (bookworm) has glibc 2.33.
# If you are using "physical" mode, please check the glibc version in your production database system to avoid potential index corruption.
# You should have the same version of glibc as in your Docker image.
# https://gitlab.com/postgres-ai/custom-images/-/blob/master/extended-postgres/Dockerfile
ARG PG_SERVER_VERSION=15

# build-env
FROM postgres:${PG_SERVER_VERSION}-bookworm as build-env

ARG TARGETPLATFORM

ARG GO_VERSION
ENV GO_VERSION=${GO_VERSION:-1.20.3}

ARG WALG_VERSION
ENV WALG_VERSION=${WALG_VERSION:-2.0.1}

RUN apt-get clean && rm -rf /var/lib/apt/lists/partial \
    # install dependencies
    && apt-get update -o Acquire::CompressionTypes::Order::=gz \
    && apt-get install --no-install-recommends -y apt-transport-https ca-certificates \
       wget curl sudo git make cmake gcc build-essential \
       libbrotli-dev liblzo2-dev libsodium-dev \
    # install Go
    && cd /tmp && GO_ARCH=$(if [ -z "${TARGETPLATFORM}" ]; then echo "amd64"; else echo ${TARGETPLATFORM} | cut -d '/' -f2; fi) \
      && export PATH=$PATH:/usr/local/go/bin && wget https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz \
      && rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz \
      && export PATH=$PATH:/usr/local/go/bin \
    # build WAL-G
    && cd /tmp && git clone --branch v${WALG_VERSION} --single-branch https://github.com/wal-g/wal-g.git \
      && cd wal-g && export USE_LIBSODIUM=1 && export USE_LZO=1 \
      && make deps && GOBIN=/usr/local/bin make pg_install


# Build the extended image
FROM postgres:${PG_SERVER_VERSION}-bookworm

COPY --from=build-env /usr/local/bin/wal-g /usr/local/bin/wal-g

ARG PG_SERVER_VERSION
ENV PG_SERVER_VERSION=${PG_SERVER_VERSION:-15}


RUN apt-get clean && rm -rf /var/lib/apt/lists/partial \
    # remove the "beta" and "rc" suffix in the PG_SERVER_VERSION variable (if exists)
    && PG_SERVER_VERSION="$( echo ${PG_SERVER_VERSION} | sed 's/beta.*//' | sed 's/rc.*//' )" \
    && apt-get update -o Acquire::CompressionTypes::Order::=gz \
    && apt-get install --no-install-recommends -y wget make gcc unzip sudo git \
       curl libc6-dev apt-transport-https ca-certificates pgxnclient bc \
       build-essential libssl-dev krb5-multidev libkrb5-dev lsb-release apt-utils \
    && apt-get install --no-install-recommends -y postgresql-server-dev-${PG_SERVER_VERSION} \
    # amcheck extension; not included in contrib for Postgres 9.6
    && if [ "${PG_SERVER_VERSION}" = "9.6" ]; then \
         apt-get install --no-install-recommends -y postgresql-9.6-amcheck; \
       fi \
    # pg_repack extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-repack \
    # hypopg extension
    && apt-get install --no-install-recommends -y \
       postgresql-${PG_SERVER_VERSION}-hypopg \
       postgresql-${PG_SERVER_VERSION}-hypopg-dbgsym \
    # pgaudit extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-pgaudit \
    # pg_hint_plan extension
    && export PG_PLAN_HINT_VERSION=$(echo $PG_SERVER_VERSION | sed 's/\.//') \
       && wget --quiet -O /tmp/pg_hint_plan.zip \
         https://github.com/ossc-db/pg_hint_plan/archive/PG${PG_PLAN_HINT_VERSION}.zip \
       && unzip /tmp/pg_hint_plan.zip -d /tmp \
       && cd /tmp/pg_hint_plan-PG${PG_PLAN_HINT_VERSION} \
       && make && make install \
    # powa extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-powa \
    # pg_auth_mon extension
    && if [ $(echo "$PG_SERVER_VERSION < 16" | /usr/bin/bc) = "1" ]; then \
        if [ "${PG_SERVER_VERSION}" = "9.6" ]; then \
          cd /tmp && git clone --branch v1.0 --single-branch https://github.com/RafiaSabih/pg_auth_mon.git \
          && cd pg_auth_mon && USE_PGXS=1 make && USE_PGXS=1 make install; \
        elif [ $(echo "$PG_SERVER_VERSION > 10" | /usr/bin/bc) = "1" ]; then \
          cd /tmp && git clone --branch v2.0 --single-branch https://github.com/RafiaSabih/pg_auth_mon.git \
          && cd pg_auth_mon && USE_PGXS=1 make && USE_PGXS=1 make install; \
        fi \
      fi \
    # hll extension
    && apt-get install --no-install-recommends -y postgresql-"${PG_SERVER_VERSION}"-hll \
    # px_ulid
    && wget https://github.com/pksunkara/pgx_ulid/releases/download/v0.1.1/pgx_ulid-v0.1.1-pg15-amd64-linux-gnu.deb \
      && dpkg -i pgx_ulid-v0.1.1-pg15-amd64-linux-gnu.deb \
      && rm -rf pgx_ulid-v0.1.1-pg15-amd64-linux-gnu.deb \
    # pg_show_plans extension
    && if [ $(echo "$PG_SERVER_VERSION > 11" | /usr/bin/bc) = "1" ]; then \
         cd /tmp && git clone https://github.com/cybertec-postgresql/pg_show_plans.git \
         && cd pg_show_plans \
         && export USE_PGXS=1 && make && make install; \
       fi \
    # postgresql_anonymizer extension
    && pgxn install ddlx && pgxn install postgresql_anonymizer \
    # pgMemento
    && pgxn install pgmemento \
    # pg_partman
    && pgxn install pg_partman \
    # pg_stat_kcache extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-pg-stat-kcache \
    # pg_wait_sampling extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-pg-wait-sampling \
    # pg_qualstats extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-pg-qualstats \
    # bg_mon extension
    && apt-get install -y libevent-dev libbrotli-dev \
      && cd /tmp && git clone https://github.com/CyberDem0n/bg_mon.git && cd bg_mon \
      && USE_PGXS=1 make && USE_PGXS=1 make install && cd .. \
    # pgextwlist extension
    && apt-get install --no-install-recommends -y postgresql-${PG_SERVER_VERSION}-pgextwlist \
    # pgBackRest
    && apt-get install --no-install-recommends -y \
       pgbackrest zstd openssh-client \
       && mkdir -p -m 700 /var/lib/postgresql/.ssh \
       && chown postgres:postgres /var/lib/postgresql/.ssh \
    # remove all auxilary packages to reduce final image size
    && cd / && rm -rf /tmp/* && apt-get purge -y --auto-remove \
       gcc make wget unzip curl libc6-dev apt-transport-https git \
       postgresql-server-dev-${PG_SERVER_VERSION} pgxnclient build-essential \
       libssl-dev krb5-multidev comerr-dev krb5-multidev libkrb5-dev apt-utils lsb-release \
       libgssrpc4 libevent-dev libbrotli-dev \
    && apt-get clean -y autoclean \
    && rm -rf /var/lib/apt/lists/* \
    # remove standard pgdata
    && rm -rf /var/lib/postgresql/${PG_SERVER_VERSION}/ 

EXPOSE 5432

# Prepare Postgres start script
RUN echo "#!/bin/bash" > /pg_start.sh && chmod a+x /pg_start.sh \
    && echo "chown -R postgres:postgres \${PGDATA} /var/run/postgresql" \
      >> /pg_start.sh \
    && printf "sudo -Eu postgres /usr/lib/postgresql/$(echo ${PG_SERVER_VERSION} | sed 's/beta.*//' | sed 's/rc.*//')/bin/postgres -D \${PGDATA} >& /proc/1/fd/1 \n" \
      >> /pg_start.sh \
    # Infinite sleep to allow restarting Postgres
    && echo "/bin/bash -c \"trap : TERM INT; sleep infinity & wait\"" \
      >> /pg_start.sh

CMD ["/pg_start.sh"]
