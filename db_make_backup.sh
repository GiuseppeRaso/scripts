#!/bin/bash

# DB Container Backup Script Template
# ---
# This backup script can be used to automatically backup databases in docker containers.
# It currently supports mariadb and mysql
# 

DAYS=3
BACKUPDIR=/root/db_make_backup/backups

CONTAINERS=$(docker ps --format '{{.Names}}:{{.Image}}' | grep 'mysql\|mariadb' | cut -d":" -f1)
echo "list of containers: $CONTAINERS"

if [ ! -d $BACKUPDIR ]; then
    mkdir -p $BACKUPDIR
	echo "automatically created $BACKUPDIR"
fi

for CONTAINER in $CONTAINERS; do
    MYSQL_PWD=$(docker exec $CONTAINER env | grep MYSQL_ROOT_PASSWORD |cut -d"=" -f2)
	DATABASES=$(echo "show databases;" | docker exec -i -e MYSQL_PWD=$MYSQL_PWD $CONTAINER mysql -u root | grep -Ev "^(Database|mysql|performance_schema|information_schema|sys)$" | paste -sd " " -)
	echo "list of databases for container $CONTAINER: $DATABASES"
	for DB in $DATABASES; do
		docker exec -e MYSQL_PWD=$MYSQL_PWD \
			$CONTAINER /usr/bin/mysqldump -u root $DB \
			| gzip > $BACKUPDIR/$DB-$(date +"%Y%m%d%H%M").sql.gz
		echo "Backup made for $DB in container $CONTAINER"
	done
done

OLD_BACKUPS=$(ls -1 $BACKUPDIR/*.gz |wc -l)
if [ $OLD_BACKUPS -gt $DAYS ]; then
	find $BACKUPDIR -name "*.gz" -daystart -mtime +$DAYS -delete
	echo "Some files older than $DAYS days where deleted"
fi

echo "Backup for Databases completed"
