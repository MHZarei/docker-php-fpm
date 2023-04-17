FROM php:7.3-fpm

ARG TIMEZONE

LABEL author="MHZarei"

RUN apt-get update
RUN apt-get install -y \
    nginx \
    openssl \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libgmp-dev \
    libmcrypt-dev \ 
    libjpeg62-turbo-dev libjpeg-dev \
    libxml2-dev \
    nano


# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
&& composer --version

# Set timezone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone \
&& printf '[PHP]\ndate.timezone = "%s"\n', ${TIMEZONE} > /usr/local/etc/php/conf.d/tzone.ini \
&& "date"

# Type docker-php-ext-install to see available extensions
RUN docker-php-ext-install -j "$(nproc)" pdo pdo_mysql


# install xdebug
# RUN pecl install xdebug \
# && docker-php-ext-enable xdebug \
# && echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
# && echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
# && echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
# && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
# && echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
# && echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
# && echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN docker-php-ext-configure intl
RUN docker-php-ext-install -j "$(nproc)" intl

# RUN docker-php-ext-configure gd
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr  # --with-webp-dir=/usr # --with-freetype-dir=/usr 
RUN docker-php-ext-install -j "$(nproc)" gd

RUN docker-php-ext-configure exif
RUN docker-php-ext-install exif 

RUN docker-php-ext-configure zip
RUN docker-php-ext-install -j "$(nproc)" zip

RUN docker-php-ext-configure gmp 
RUN docker-php-ext-install -j "$(nproc)" gmp

RUN docker-php-ext-install soap

#RUN docker-php-ext-configure mcrypt 
#RUN docker-php-ext-install mcrypt

RUN pecl upgrade timezonedb

#RUN echo extension=mcrypt.so > $PHP_INI_DIR/conf.d/mcrypt.ini

RUN echo 'alias sf="php app/console"' >> ~/.bashrc \
&& echo 'alias sf3="php bin/console"' >> ~/.bashrc

WORKDIR /var/www/symfony

# setup nginx

ADD nginx.conf /etc/nginx/
ADD symfony.conf /etc/nginx/sites-available/

RUN ln -s /etc/nginx/sites-available/symfony.conf /etc/nginx/sites-enabled/symfony \
&& rm /etc/nginx/sites-enabled/default

RUN echo "upstream php-upstream { server localhost:9000; }" > /etc/nginx/conf.d/upstream.conf

RUN sed -i 's/CipherString/#CipherString/g' /etc/ssl/openssl.cnf

# RUN usermod -u 1000 www-data

ADD ./start.sh /start.sh

CMD ["/bin/bash", "/start.sh"]

EXPOSE 80
EXPOSE 443
