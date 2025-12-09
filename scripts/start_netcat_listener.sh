#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo "Error: Usage $0 <LISTENER_PORT>"
  exit 1
else
  ssh loadbalancer "nc -lk4 $1"
fi