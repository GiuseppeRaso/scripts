#!/bin/bash

# DB Container Backup Script Template
# ---
# This backup script can be used to automatically backup databases in docker containers.
# It currently supports mariadb, mysql and bitwardenrs containers.
# 

DAYS=7
BACKUPDIR=/root/db_backups


# backup all mysql/mariadb containers

CONTAINER=$(docker ps --format '{{.Names}}:{{.Image}}' | grep 'mysql\|mariadb' | cut -d":" -f1)

echo $CONTAINER

if [ ! -d $BACKUPDIR ]; then
    mkdir -p $BACKUPDIR
fi

for i in $CONTAINER; do
    MYSQL_PWD=$(docker exec $i env | grep MYSQL_ROOT_PASSWORD |cut -d"=" -f2)

    docker exec \
        $i /usr/bin/mysqldump -u root -p $MYSQL_PWD --all-databases \
        | gzip > $BACKUPDIR/$i-DB-$(date +"%Y%m%d%H%M").sql.gz

    OLD_BACKUPS=$(ls -1 $BACKUPDIR/$i*.gz |wc -l)
    if [ $OLD_BACKUPS -gt $DAYS ]; then
        find $BACKUPDIR -name "$i*.gz" -daystart -mtime +$DAYS -delete
    fi
done

echo "$TIMESTAMP Backup for Databases completed"
