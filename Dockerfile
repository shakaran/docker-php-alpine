FROM php:7.2-fpm-alpine
LABEL Description="Application container"

ENV PS1='\[\033[1;32m\]🐳 \[\033[1;36m\][\u\033[38;05;224m@\h\[\033[1;36m\]] \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'

## Looked here: <https://github.com/prooph/docker-files/blob/master/php/7.2-cli>
ENV PHP_REDIS_VERSION 4.1.1
ENV PHP_PTHREADS_VERSION 3.2.0

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV PATH /scripts:/scripts/aliases:$PATH

ADD composer.sh /

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    pcre-dev \
    make \
    pkgconf \
    re2c \
    # for GD
    freetype-dev \
    libpng-dev  \
    libjpeg-turbo-dev \
    libxslt-dev

RUN apk add --no-cache --virtual .persistent-deps \
    # for intl extension
    icu-dev \
    # for postgres
    postgresql-dev \
    # for soap
    libxml2-dev \
    # for GD
    freetype \
    libpng \
    libjpeg-turbo \
    # for bz2 extension
    bzip2-dev \
    # for intl extension
    libintl gettext-dev libxslt \
    # for event extension
    libevent-dev \
    # for gmp
    gmp gmp-dev \
    # for imagick extension
    imagemagick-dev \
    # etc
    bash nano \
    git \
    unzip \
    && set -xe \
    # workaround for rabbitmq linking issue
    && ln -s /usr/lib /usr/local/lib64 \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure gmp --enable-gmp \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-configure mysqli --with-mysqli \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure pdo_pgsql --with-pgsql \
    && docker-php-ext-configure mbstring --enable-mbstring \
    && docker-php-ext-configure soap --enable-soap \
    && docker-php-ext-configure zip --enable-zip \
#    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gmp \
        gd \
        intl \
        pcntl \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        mbstring \
        soap \
        iconv \
        bz2 \
        calendar \
        exif \
        gettext \
        shmop \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        wddx \
        xsl \
        zip \
#        opcache \
#    && echo -e "opcache.memory_consumption=128\n\
#opcache.interned_strings_buffer=8\n\
#opcache.max_accelerated_files=4000\n\
#opcache.revalidate_freq=60\n\
#opcache.fast_shutdown=1\n\
#opcache.enable_cli=1\n\
#opcache.enable=1\n" > /usr/local/etc/php/conf.d/opcache.ini \
    && pecl install trader \
    && docker-php-ext-enable trader \
    && pecl install event \
    && docker-php-ext-enable event  \
    && mv /usr/local/etc/php/conf.d/docker-php-ext-event.ini /usr/local/etc/php/conf.d/docker-php-ext-zz-event.ini \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    # phpredis
    && git clone --branch ${PHP_REDIS_VERSION} https://github.com/phpredis/phpredis /tmp/phpredis \
        && cd /tmp/phpredis \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
        && echo 'extension=redis.so' > /usr/local/etc/php/conf.d/redis.ini \
    # pthreads
    # && git clone --branch ${PHP_PTHREADS_VERSION} https://github.com/krakjoe/pthreads.git /tmp/pthreads \
    #     && cd /tmp/pthreads \
    #     && phpize  \
    #     && ./configure  \
    #     && make  \
    #     && make install \
    #     && make test \
    #     && echo 'extension=pthreads.so' > /usr/local/etc/php/conf.d/pthreads.ini \
    && apk del .build-deps \
    && rm -rf /tmp/* \
    && rm -rf /app \
    && mkdir /app \
    && rm -rf /scripts \
    && mkdir /scripts \
    && mkdir -p /scripts/aliases \
    && rm -rf /home/user \
    && mkdir /home/user \
    && chmod 777 /home/user \
    && rm -f /docker-entrypoint.sh \
    && rm -f /usr/local/etc/php-fpm.d/* \
    && mkdir -p "$COMPOSER_HOME" \
    # install composer
    && /composer.sh "$COMPOSER_HOME" \
    && rm -f /composer.sh \
    && composer --ansi --version --no-interaction \
    && composer --no-interaction global require 'hirak/prestissimo' \
    && composer --no-interaction global require 'ergebnis/composer-normalize' \
    && composer clear-cache \
    && rm -rf /tmp/composer-setup.php /tmp/.htaccess \
    # show php info
    && php -v \
    && php-fpm -v \
    && php -m

COPY ./aliases/* /scripts/aliases/
COPY ./etc/bin/* /usr/local/bin/
COPY ./keep-alive.sh /scripts/keep-alive.sh
COPY ./fpm-entrypoint.sh /fpm-entrypoint.sh
COPY ./fpm-command.sh /fpm-command.sh
COPY ./etc/php/php-dev.ini /usr/local/etc/php/php.ini
COPY ./etc/php/php-fpm.conf /usr/local/etc/php-fpm.conf

WORKDIR /var/www
ENTRYPOINT []
CMD []
