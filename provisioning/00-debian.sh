#!/bin/bash -ex

if [ "$EUID" -ne 0 ]; then
  exec sudo -- "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get dist-upgrade -y
apt-get install -y \
  build-essential \
  curl \
  libyaml-dev \
  python \
  python-dev \
  python-pip

pip install awscli
