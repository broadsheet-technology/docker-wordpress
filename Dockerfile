FROM wordpress:php8.1-fpm

# 0/ set labels
LABEL maintainer="Will Haynes <will@broadsheet.technology>"
LABEL version="0.5"
LABEL description="A tunable & performant Docker image for running WordPress."

# 1/ Install programs
RUN pecl install redis && docker-php-ext-enable redis
RUN apt-get update && apt-get -y install cron wget gnupg2

# 2/ Install new relic php agent
RUN echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list
RUN wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
RUN apt-get update -y
RUN apt-get install newrelic-php5 -y; NR_INSTALL_SILENT=1 newrelic-install install; exit 0

# 3/ Install crontab
RUN crontab -u www-data -l | { cat; echo "*/5 * * * * /usr/local/bin/php -q /var/www/html/wp-cron.php > /tmp/cron"; } | crontab -u www-data -

# 4/ Install scripts
ADD docker-entrypoint.sh /usr/local/bin/local-docker-entrypoint.sh
RUN chmod 0644 /usr/local/bin/local-docker-entrypoint.sh

# 5/ Inject local-docker-entrypoint.sh before running the one supplied by WordPress
CMD bash /usr/local/bin/local-docker-entrypoint.sh && bash /usr/local/bin/docker-entrypoint.sh php-fpm