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

echo "image: ${image}"

platforms=${PLATFORMS:-"linux/amd64,linux/arm64"}
echo "platforms: ${platforms}"

function local_build_func() {
  docker login -u "${DOCKER_REGISTRY_USERNAME}" -p "${DOCKER_REGISTRY_PASSWORD}" "${DOCKER_REGISTRY}"
  docker buildx create --use
  docker buildx build --platform ${platforms} -t "${image}" \
    --label "branch=$(git rev-parse --abbrev-ref HEAD)" \
    --label "commit=$(git rev-parse HEAD)" \
    --label "build-time=$(date '+%Y-%m-%d %T%z')" \
    --push \
    -f dockerfiles/Dockerfile .
}

function k8s_build_func() {
  buildctl --addr tcp://buildkitd.default.svc.cluster.local:1234 \
    --tlscacert=/.buildkit/ca.pem \
    --tlscert=/.buildkit/cert.pem \
    --tlskey=/.buildkit/key.pem \
    build \
    --frontend dockerfile.v0 \
    --opt platform=${platforms} \
    --local context=/.pipeline/container/context/fluent-bit \
    --local dockerfile=/.pipeline/container/context/fluent-bit/dockerfiles \
    --output type=image,name=${image},push=true
  echo "image=${image}" >> $METAFILE
}

# switch by local or k8s
local_build=${LOCAL_BUILD:-"false"}
case $local_build in
  "true")
    echo "local build"
    local_build_func
    ;;
  "false")
    echo "k8s build"
    k8s_build_func
    ;;
  *)
    echo "unknown build"
    exit 1
    ;;
esac
