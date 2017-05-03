FROM ubuntu:latest
# system dependencies
RUN apt-get update && apt-get install -y vim curl wget git composer apache2 php libapache2-mod-php mysql-client php-xml php-mysql php-curl php-ldap expect pv

# Enable apache mods
# mod_ssl
RUN a2enmod ssl && a2ensite default-ssl
# mod_rewrite
RUN a2enmod rewrite
# upload site-magento.conf to apache config directory
COPY site-magento.conf /etc/apache2/sites-enabled/

# create magneto user
RUN useradd -m magento
RUN usermod -g www-data magento

# entrypoint
COPY tunneler.exp /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
