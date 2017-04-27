#!/bin/sh

usermod -u ${LOCAL_USER_ID} magento
groupmod -g ${LOCAL_GROUP_ID} magento

chown -R magento:www-data /var/www/html

# replace config variables
sed -i "s/{db_host}/$DB_HOST/g; \
		s/{db_user}/$DB_USER/g; \
		s/{db_password}/$DB_PASSWORD/g; \
		s/{db_name}/$DB_NAME/g; \
		s/{redis_host}/$REDIS_HOST/g; \
		s/{redis_session_port}/$REDIS_SESSION_PORT/g; \
		s/{redis_fpc_port}/$REDIS_FPC_PORT/g; \
		s/{redis_fpc_prefix}/$REDIS_FPC_PREFIX/g; \
		s/{redis_cache_port}/$REDIS_CACHE_PORT/g; \
		s/{redis_cache_prefix}/$REDIS_CACHE_PREFIX/g" /var/www/html/app/etc/local.xml

# MAIN
exec apachectl -D FOREGROUND

# exec gosu magento bash -c "magento setup:store-config:set && magento setup:db-schema:upgrade && magento setup:db-data:upgrade"
