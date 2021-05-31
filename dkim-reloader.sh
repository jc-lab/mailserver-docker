#!/bin/bash

watch_dir=$(dirname $DKIM_KEYFILE)

while true; do
  if [[ "$(inotifywatch -e modify,create,delete -t 3 ${watch_dir} 2>&1)" =~ "${watch_dir}" ]]; then
    kill -HUP $(cat /run/opendkim/opendkim.pid)
    sleep 5
  fi
done

