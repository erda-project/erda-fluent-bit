FROM registry.erda.cloud/erda-x/golang:1.17 as gobuilder

COPY . /build
WORKDIR /build

RUN make build

FROM registry.erda.cloud/erda-x/debian:10 as builder

# Fluent Bit version
ENV FLB_MAJOR 1
ENV FLB_MINOR 9
ENV FLB_PATCH 10
ENV FLB_VERSION 1.9.10

#ARG FLB_TARBALL=https://github.com/fluent/fluent-bit/archive/v$FLB_VERSION.tar.gz
ARG FLB_TARBALL=https://erda-project.oss-cn-hangzhou.aliyuncs.com/fluent-bit/fluent-bit-$FLB_VERSION.tar.gz
ENV FLB_SOURCE $FLB_TARBALL
RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/fluent-bit-master/

ENV DEBIAN_FRONTEND noninteractive

COPY filter_throttle_patch /tmp/filter_throttle_patch
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    cmake \
    make \
    tar \
    libssl-dev \
    libsasl2-dev \
    pkg-config \
    libsystemd-dev \
    zlib1g-dev \
    libpq-dev \
    postgresql-server-dev-all \
    flex \
    bison \
    && curl -L -o "/tmp/fluent-bit.tar.gz" ${FLB_SOURCE} \
    && cd tmp/ && mkdir fluent-bit \
    && tar zxfv fluent-bit.tar.gz -C ./fluent-bit --strip-components=1 \
    && cd fluent-bit/build/ \
    && rm -rf /tmp/fluent-bit/build/* \
    && if [ "$FLB_VERSION" = "1.9.3" ] ; then rm -rf /tmp/fluent-bit/plugins/filter_throttle/throttle.c;  rm -rf /tmp/fluent-bit/plugins/filter_throttle/throttle.h; cp /tmp/filter_throttle_patch/v1.9.3/* /tmp/fluent-bit/plugins/filter_throttle/; fi

WORKDIR /tmp/fluent-bit/build/
RUN cmake -DFLB_RELEASE=On \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_TLS=On \
          -DFLB_SHARED_LIB=Off \
          -DFLB_EXAMPLES=Off \
          -DFLB_HTTP_SERVER=On \
          -DFLB_IN_SYSTEMD=On \
          -DFLB_OUT_KAFKA=On \
          -DFLB_CONFIG_YAML=Off \
          -DFLB_OUT_PGSQL=On .. \
          -DFLB_JEMALLOC_OPTIONS="--with-lg-page=16 --with-lg-quantum=3"

RUN make -j $(getconf _NPROCESSORS_ONLN)
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
#COPY conf/fluent-bit.conf \
#     conf/parsers.conf \
#     conf/parsers_ambassador.conf \
#     conf/parsers_java.conf \
#     conf/parsers_extra.conf \
#     conf/parsers_openstack.conf \
#     conf/parsers_cinder.conf \
#     conf/plugins.conf \
#     /fluent-bit/etc/

COPY conf/ /fluent-bit/etc/
COPY entrypoint.sh /fluent-bit/etc/

COPY --from=gobuilder /build/out_erda.so /fluent-bit/bin/

FROM registry.erda.cloud/erda-x/debian:10

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash gdb valgrind build-essential vim curl sqlite3 ca-certificates libpq5

COPY --from=builder /fluent-bit /fluent-bit

CMD ["/fluent-bit/etc/entrypoint.sh"]
