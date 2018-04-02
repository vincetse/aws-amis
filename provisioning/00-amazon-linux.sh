#!/bin/bash -ex

if [ "$EUID" -ne 0 ]; then
  exec sudo -- "$0" "$@"
fi

yum update -y
yum install -y \
  aws-cli \
  curl \
  python \
