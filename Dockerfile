# Dockerfile
FROM ghcr.io/laveracloudsolutions/php:8.5-apache

# Installation des dépendances
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -y \
        apache2 \
        ca-certificates \
        curl \
        dnsutils \
        expat \
        fontconfig \
        git \
        gnupg \
        gnutls-bin \
        iputils-ping \
        libapache2-mod-security2 \
        libc6 \
        libfreetype6-dev \
        libfreetype6 \
        libgrpc++-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libjpeg62-turbo \
        libpng-dev \
        libpng16-16 \
        libpq-dev \
        libsqlite3-0 \
        libxml2-dev \
        libxrender1 \
        libzip-dev \
        linux-libc-dev \
        net-tools \
        perl \
        xz-utils \
        unzip \
        vim \
        xfonts-75dpi \
        xfonts-base \
        xvfb \
        zip \
        zlib1g-dev && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP Extensions
RUN docker-php-ext-configure zip && \
    docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j"$(nproc)" intl pgsql pdo pdo_pgsql opcache zip gd

# PHP Extensions (Opentelemetry)
RUN pecl install opentelemetry protobuf
RUN docker-php-ext-enable opentelemetry protobuf

# Install GRPC (pour OpenTeletry) > PECL installation is far too long, so install manually (@see https://stackoverflow.com/a/78683184)
RUN git clone --depth 1 -b v1.64.x https://github.com/grpc/grpc /tmp/grpc \
    && cd /tmp/grpc/src/php/ext/grpc \
    && phpize && ./configure && make && make install \
    && rm -rf /tmp/grpc
RUN docker-php-ext-enable grpc

# Enable apache modules
RUN a2enmod headers
RUN a2enmod rewrite remoteip security2

# Set timezone to Paris
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

EXPOSE 8080
WORKDIR /var/www/html

# COPY configuration BEFORE install extentions/plugins
COPY ./config/php/php.ini /usr/local/etc/php/php.ini
COPY ./config/apache/VirtualHost.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/apache/apache2.conf /etc/apache2/apache2.conf
COPY ./config/apache/ports.conf /etc/apache2/ports.conf
COPY ./config/apache/mods-enabled/deflate.conf /etc/apache2/mods-enabled/deflate.conf