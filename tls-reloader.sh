#!/bin/bash

watch_dir=/secret

while true; do
  if [[ "$(inotifywatch -e modify,create,delete -t 3 ${watch_dir} 2>&1)" =~ "${watch_dir}" ]]; then
    postfix reload
    dovecot reload
    sleep 5
  fi
done

