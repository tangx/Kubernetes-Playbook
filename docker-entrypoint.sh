#!/bin/bash
if [[ $@ = 'bash' ]]; then
    exec "$@"
else
    if [ $(ls /etc/kubernetes | wc -l) -eq 0 ];then
        /playbook/Make_SSL.sh
    fi
    exec "$@"
fi