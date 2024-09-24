FROM php:8-fpm-alpine

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
RUN delgroup dialout

# Add the laravel user and group
RUN addgroup -g ${GID} --system laravel
RUN adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel

# Update php-fpm configuration to use the laravel user
RUN sed -i "s/user = www-data/user = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Install necessary packages
RUN apk add --no-cache \
    icu-dev \
    zip \
    libzip-dev \
    libintl \
    oniguruma-dev \
    curl \
    gcc \
    make \
    autoconf \
    g++ \
    libc-dev \
    linux-headers \
    && docker-php-ext-install \
    pdo_mysql \
    intl \
    zip \
    pcntl

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# RUN docker-php-ext-install pdo pdo_mysql

# Install Redis extension manually
RUN mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/5.3.4.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

# Give ownership of the /var/www/html directory to the laravel user
# RUN chown -R laravel:laravel /var/www/html
RUN chown -R laravel:laravel /var/www/html && chmod -R 775 /var/www/html

USER laravel

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
