#!/bin/bash

count=""
while [[ "${count}" != "11" ]]; do
	count=$(docker ps | grep bitwarden | awk '{count+=gsub(/\(healthy\)/,"")} END {print count+0}')
	sleep 1
done
sleep 5
docker exec bitwarden-mssql /bin/bash /backup-db.sh
