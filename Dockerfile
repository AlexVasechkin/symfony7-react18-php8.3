# базовый образ
FROM php:8.3-fpm as install-packages

RUN apt-get update \
 && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    git \
    graphviz \
    curl \
    supervisor

RUN mkdir -p /tmp/composer \
 && cd /tmp/composer \
 && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php \
 && php -r "unlink('composer-setup.php');" \
 && mv composer.phar /usr/local/bin/composer \
 && cd /var/www/html \
 && rm -rf /tmp/composer


FROM install-packages as install-php-extensions

RUN docker-php-ext-install zip
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-install opcache
RUN apt-get update \
 && apt-get install -y libpq-dev \
 && docker-php-ext-install pdo pdo_pgsql pgsql
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install sockets \
 && docker-php-ext-enable sockets
RUN pecl install --force redis \
 && rm -rf /tmp/pear \
 && docker-php-ext-enable redis
RUN apt-get install -y libcurl4-openssl-dev \
    pkg-config \
    libssl-dev
RUN apt-get install -y librabbitmq-dev \
 && pecl install --force amqp \
 && rm -rf /tmp/pear \
 && docker-php-ext-enable amqp


FROM install-php-extensions as install-symfony

RUN mkdir -p /tmp/symfony \
 && cd /tmp/symfony \
 && curl -sS https://get.symfony.com/cli/installer | bash \
 && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony \
 && cd /var/www/html \
 && rm -rf /tmp/symfony


FROM install-symfony as build-app

RUN rm /usr/local/etc/php-fpm.d/www.conf \
 && rm -rf /etc/nginx/sites-enabled/* \
 && rm -rf /etc/nginx/conf.d/*

COPY ./php/conf.d/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY ./php/www.conf /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

ENV APP_ENV=prod

COPY app/ /var/www/html/

RUN rm -rf ./var \
 && rm -rf ./vendor \
 && rm -rf ./node_modules \
 && rm -rf ./composer.lock \
 && rm -rf ./package-lock.json \
 && rm -rf ./.env.*

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN composer install

RUN chown -R www-data:root /var/www/html/var

RUN chown -R www-data:www-data /var/www/html/public

ARG FRONT_SCRIPT=dev

RUN mkdir -p /tmp/node && \
    cd /tmp/node && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update -qq && \
    apt-get install -y nodejs && \
    cd /var/www/html && \
    npm i && \
    npm run ${FRONT_SCRIPT} && \
    apt-get remove -y nodejs && \
    rm -rf /var/www/html/node_modules

EXPOSE 80

COPY ./supervisor/conf/supervisord.conf /etc/supervisor/supervisord.conf

COPY ./supervisor/conf/conf.d /etc/supervisor/conf.d
