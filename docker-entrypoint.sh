#!/bin/bash

# 1/ configure new-relic php agent
update_newrelic_config() {
    local license_key="$1"
    local app_name="$2"
    if [[ -n "$license_key" ]]; then
        sed -i -e "s/REPLACE_WITH_REAL_KEY/$license_key/" "$(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini"
        if [[ -n "$app_name" ]]; then
            sed -i -e "s/newrelic.appname.*/newrelic.appname=\"$app_name\"/" "$(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini"
        fi
    else
        echo "No NRIA_LICENSE_KEY found. Skipping New Relic configuration"
    fi
}
update_newrelic_config "$NRIA_LICENSE_KEY" "$NRIA_APP_NAME"

# 2/ generate php-fpm.conf and php.ini from environment variables
cat <<EOF > /usr/local/etc/php-fpm.d/zzz-broadsheet.technology-wordpress-extra.conf
[www]
pm = ${BT_PHP_PM:-dynamic}
pm.max_children = ${BT_PHP_PM_MAX_CHILDREN:-10}
pm.max_requests = ${BT_PHP_PM_MAX_REQUESTS:-200}
EOF

cat <<EOF > /usr/local/etc/php/conf.d/zzz-broadsheet.technology-wordpress-extra.ini
file_uploads = On
memory_limit = 264M
upload_max_filesize = ${BT_PHP_UPLOAD_MAX_FILESIZE:-6M}
post_max_size = 64M
max_execution_time = 600

opcache.max_accelerated_files=${BT_PHP_OPCACHE_MAX_ACCELERATED_FILES}
opcache.memory_consumption=${BT_PHP_OPCACHE_MEMORY_CONSUMPTION}
EOF

# 3/ copy theme
cd /srv/themes && for dir in */; do [ -d "/var/www/html/wp-content/themes/$dir" ] || cp -r "$dir" "/var/www/html/wp-content/themes"; done

# 4/ dump ENV variables into cron environment & start cron service
printenv > /etc/environment
service cron start