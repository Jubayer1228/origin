#!/bin/bash

# This script builds and pushes a release to DockerHub.
source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

tag="${OS_TAG:-}"
if [[ -z "${tag}" ]]; then
  if [[ "$( git tag --points-at HEAD | wc -l )" -ne 1 ]]; then
    os::log::error "Specify OS_TAG or ensure the current git HEAD is tagged."
    exit 1
  fi
  tag="$( git tag --points-at HEAD )"
elif [[ "$( git rev-parse "${tag}" )" != "$( git rev-parse HEAD )" ]]; then
  os::log::warning "You are running a version of hack/release.sh that does not match OS_TAG - images may not be build correctly"
fi

function removeimage() {
  for i in $@; do
    if docker inspect $i &>/dev/null; then
      docker rmi $i
    fi
    if docker inspect docker.io/$i &>/dev/null; then
      docker rmi docker.io/$i
    fi
  done
}

# Ensure that the build is using the latest public base images
removeimage openshift/origin-base openshift/origin-release openshift/origin-haproxy-router-base
docker pull openshift/origin-base
docker pull openshift/origin-release
docker pull openshift/origin-haproxy-router-base

OS_GIT_COMMIT="${tag}" hack/build-release.sh
hack/build-images.sh
OS_PUSH_TAG="${tag}" OS_TAG="" OS_PUSH_LOCAL="1" hack/push-release.sh

echo
echo "Pushed ${tag} to DockerHub"
echo "1. Push tag to GitHub with: git push origin --tags # (ensure you have no extra tags in your environment)"
echo "2. Create a new release on the releases page and upload the built binaries in _output/local/releases"
echo "3. Send an email"