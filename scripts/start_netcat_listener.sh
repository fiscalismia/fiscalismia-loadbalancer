#!/usr/bin/env bash

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Error: Usage $0 <SSH_ALIAS> <LISTENER_PORT>"
  exit 1
else
  ssh $1 "nc -lk4 $2"
fi