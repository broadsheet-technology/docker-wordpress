## broadsheet.technology/wordpress

A tunable & performant Docker image for running WordPress.

## Environment Variables

### WordPress

At a minimum, you will need to define the following environment variables:

| Environment Variable    | Description                                   |
| ----------------------- | --------------------------------------------- |
| `WORDPRESS_DB_HOST`     | The hostname of the database server.          |
| `WORDPRESS_DB_USER`     | The username used to connect to the database. |
| `WORDPRESS_DB_PASSWORD` | The password used to connect to the database. |
| `WORDPRESS_DB_NAME`     | The name of the database to use.              |

See the official [Docker WordPress documentation](https://github.com/docker-library/docs/tree/master/wordpress#how-to-use-this-image) for more information on the environment variables that can be used to configure the WordPress container.

### broadsheet.technology/wordpress

There is additional configuration to tune the PHP-FPM process manager and the PHP opcode cache for production environments. These are optional, but recommended.

| Environment Variable                   | Description                                                                                          |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `BT_PHP_PM`                            | Process manager to be used by PHP-FPM. Can be either `static` or `dynamic`.                          |
| `BT_PHP_PM_MAX_CHILDREN`               | Maximum number of child processes that can be active at the same time for each PHP-FPM process pool. |
| `BT_PHP_PM_MAX_REQUESTS`               | Maximum number of requests each child process should execute before respawning.                      |
| `BT_PHP_UPLOAD_MAX_FILESIZE`           | Maximum size of uploaded files. (default: 6M)                                                        |
| `BT_PHP_OPCACHE_MAX_ACCELERATED_FILES` | Maximum number of files that can be stored in the opcode cache.                                      |
| `BT_PHP_OPCACHE_MEMORY_CONSUMPTION`    | Maximum amount of memory that can be used by the opcode cache.                                       |

### New Relic

(Optional) If you have a New Relic account, you can enable New Relic observability by setting the following environment variables:

| Environment Variable | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| `NRIA_LICENSE_KEY`   | (Optional) License key for New Relic account.                       |
| `NRIA_APP_NAME`      | (Optional) The name of your application as it appears in New Relic. |

## Example usage in Docker Compose

```bash
# Docker:
COMPOSE_PROJECT_NAME=localhost-wordpress

# App:
SITE_URL=localhost
SITE_WP_CONTENT_DIR=/bin/wp-content

# broadsheet.technology/wordpress:
BT_PHP_PM_MAX_CHILDREN=30
BT_PHP_PM_MAX_REQUESTS=500
BT_PHP_UPLOAD_MAX_FILESIZE=6M
BT_PHP_OPCACHE_MAX_ACCELERATED_FILES=20000
BT_PHP_OPCACHE_MEMORY_CONSUMPTION=256

# Wordpress:
WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress

# Redis:
REDIS_PASSWORD=12345
```

```yaml
version: "3"

services:
  wordpress:
    build:
      context: config/wordpress
    container_name: ${COMPOSE_PROJECT_NAME}-wordpress
    links:
      - redis
    expose:
      - 80
    restart: always
    logging:
      options:
        max-size: 10m
        max-file: 10
    volumes:
      - ./config/wordpress/wp-content/object-cache.php:/var/www/html/wp-content/object-cache.php
      - ${COMPOSE_PROJECT_NAME}-wordpress:/var/www/html
      - ./${SITE_WP_CONTENT_DIR}:/var/www/html/wp-content
    environment:
      WORDPRESS_DB_HOST: ${WORDPRESS_DB_HOST}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
      WORDPRESS_CONFIG_EXTRA: /* Domain */
        define('WP_HOME','https://${SITE_URL}');
        define('WP_SITEURL','https://${SITE_URL}');
        define('WP_CACHE',true);
        define('WP_MEMORY_LIMIT','128M');
        define('WP_REDIS_HOST', 'redis');
        define('WP_REDIS_PASSWORD', '${REDIS_PASSWORD}' );
        define('WP_CACHE_KEY_SALT', '${SITE_URL}');
        define('DISABLE_WP_CRON', true);
        $$memcached_servers = array(
        'default' => array(
        'memcached:11211',
        )
        );

  redis:
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    image: redis:6
    restart: always
    logging:
      options:
        max-size: 10m
        max-file: 10
    ports:
      - "6379:6379"

volumes:
  ${COMPOSE_PROJECT_NAME}-wordpress:

networks:
  default:
    name: ${COMPOSE_PROJECT_NAME}-network
    external: true
```
