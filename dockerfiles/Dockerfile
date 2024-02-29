# build erda.so
FROM registry.erda.cloud/erda-x/golang:1.17 as gobuilder

COPY . /build
WORKDIR /build

RUN make build

# bitnami/fluent-bit (gnu sed checked)
FROM bitnami/fluent-bit:2.2.2 AS fluentbit
USER root

RUN ln -s /opt/bitnami/fluent-bit /fluent-bit
WORKDIR /fluent-bit
RUN mkdir -p {etc,bin}

COPY conf/ entrypoint.sh etc/
COPY --from=gobuilder /build/out_erda.so bin/

ENTRYPOINT ["/fluent-bit/etc/entrypoint.sh"]
