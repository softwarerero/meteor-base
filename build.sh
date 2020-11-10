#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o allexport


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

METEOR_VERSION=${1:-1.11.1}  

build_cmd() {
	docker build --build-arg "METEOR_VERSION=$METEOR_VERSION" --tag softwarerero/meteor-base:"$METEOR_VERSION" ./src
}

build() {
	# Retry up to five times
	build_cmd $METEOR_VERSION || build_cmd $METEOR_VERSION || build_cmd $METEOR_VERSION || build_cmd $METEOR_VERSION || build_cmd $METEOR_VERSION
}


source ./versions.sh

building_all_versions=true
if [ -n "${CI_VERSION:-}" ]; then
	meteor_versions=( "${CI_VERSION:-}" )
	building_all_versions=false
elif [[ "${1-x}" != x ]]; then
	meteor_versions=( "$METEOR_VERSION" )
	building_all_versions=false
fi


for version in "${meteor_versions[@]}"; do
	printf "${GREEN}Building Docker base image for Meteor ${version}...${NC}\n"
	if ! build $version; then
		printf "${RED}Error building Docker base image for Meteor ${version}${NC}\n"
		exit 1
	fi
done

if [[ $building_all_versions ]]; then
	docker tag softwarerero/meteor-base:"${version}" softwarerero/meteor-base:latest
	printf "${GREEN}Success building Docker base images for all supported Meteor versions\n"
else
	printf "${GREEN}Success building Docker base images for Meteor versions ${meteor_versions}\n"
fi
