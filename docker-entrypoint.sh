#!/bin/sh

usermod -u ${LOCAL_USER_ID} magento
groupmod -g ${LOCAL_GROUP_ID} magento

chown -R magento:www-data /var/www/magento
chown -R magento:www-data .

exec gosu magento bash -c "magento setup:store-config:set && magento setup:db-schema:upgrade && magento setup:db-data:upgrade"
