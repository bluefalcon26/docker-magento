#!/bin/bash

# for checking exit codes of tunneler.exp, mainly
set -o pipefail

echo "updating file permissions"
usermod -u ${LOCAL_USER_ID} magento
groupmod -g ${LOCAL_GROUP_ID} magento

chown -R magento:www-data /var/www/html

# replace config variables
echo "replacing config variables..."
sed -i "s/{db_host}/$DB_HOST/g; \
		s/{db_user}/$DB_USER/g; \
		s/{db_password}/$DB_PASSWORD/g; \
		s/{db_name}/$DB_NAME/g; \
		s/{redis_host}/$REDIS_HOST/g; \
		s/{redis_session_port}/$REDIS_SESSION_PORT/g; \
		s/{redis_fpc_port}/$REDIS_FPC_PORT/g; \
		s/{redis_fpc_prefix}/$REDIS_FPC_PREFIX/g; \
		s/{redis_cache_port}/$REDIS_CACHE_PORT/g; \
		s/{redis_cache_prefix}/$REDIS_CACHE_PREFIX/g" \
		/var/www/html/app/etc/local.xml

# Have we gotten the database yet?
if [ ! -s "/shared-dev.sql" ]
then
	echo "pulling remote db data..."

	# get remote db size
	db_size=$(tunneler.exp "mysql -ss -N -h$REMOTE_DB_HOST -u$REMOTE_DB_USER \
		-p$REMOTE_DB_PASSWORD -e \
		\"SELECT CEILING(SUM(data_length) / POWER(1024,2))
		    FROM information_schema.tables
		    WHERE table_schema IN ('$REMOTE_DB_NAME');\"
		")
	ret=$?

	# in case $db_size doesn't get set, or it's not a number, don't break pv
	if [ $ret -ne 0 ] || [ -z "$db_size" ]
	then db_size=0; fi

	# sanitize line breaks
	db_size=$(echo $db_size | sed -e 's/[\r\n]//g')
	echo "remote db size is $db_size"

	# pull remote db data using expect and track progress
	tunneler.exp "mysqldump -h$REMOTE_DB_HOST -u$REMOTE_DB_USER \
		    -p$REMOTE_DB_PASSWORD $REMOTE_DB_NAME" \
		| pv -f -p -s ${db_size}M \
		> /shared-dev.sql
	ret=$?

	if [ $ret -ne 0 ]
	then # failed
		rm -f /shared-dev.sql
		# exit 1
	fi
fi
# place the pulled/exisiting dump into our target database
echo "importing data into target db..."
pv -f -p /shared-dev.sql \
	| mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE || \
# but don't fail here
	true

# MAIN
echo "starting main thread"
exec apachectl -D FOREGROUND
