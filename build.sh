#!/bin/bash

set -o errexit -o nounset -o pipefail

v="$(head -n 1 VERSION)"
v="${v}-$(date '+%Y%m%d')-$(git rev-parse --short HEAD)"

t=${IMAGE_TAG:-}
if [[ -n "$t" ]]; then
  v=$t
fi

echo "version=${v}"

image="${DOCKER_REGISTRY}/erda-fluent-bit:${v}"

echo "image=${image}"

docker login -u "${DOCKER_REGISTRY_USERNAME}" -p "${DOCKER_REGISTRY_PASSWORD}" "${DOCKER_REGISTRY}"
#docker buildx create --use
#docker buildx build --platform linux/amd64,linux/arm64 -t "${image}" \
#docker buildx build --platform linux/${ARCH} -t "${image}" \
#    --label "branch=$(git rev-parse --abbrev-ref HEAD)" \
#    --label "commit=$(git rev-parse HEAD)" \
#    --label "build-time=$(date '+%Y-%m-%d %T%z')" \
#    --push \
#    -f dockerfiles/Dockerfile .

buildctl --addr tcp://buildkitd.default.svc.cluster.local:1234 \
    --tlscacert=/.buildkit/ca.pem \
    --tlscert=/.buildkit/cert.pem \
    --tlskey=/.buildkit/key.pem \
    build \
    --frontend dockerfile.v0 \
    --opt platform=${PLATFORMS} \
    --local context=/.pipeline/container/context/fluent-bit \
    --local dockerfile=/.pipeline/container/context/fluent-bit/dockerfiles \
    --output type=image,name=${image},push=true

echo "image=${image}" >> $METAFILE
