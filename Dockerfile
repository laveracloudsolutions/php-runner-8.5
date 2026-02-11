# Dockerfile
FROM ghcr.io/laveracloudsolutions/php:8.5-apache

# Installation des dépendances
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -qy \
    apache2=2.4.* \
    ca-certificates=* \
    curl=7.* \
    dnsutils=1:9.* \
    expat=2.* \
    fontconfig=2.* \
    git=1:2.39.* \
    gnupg=2.* \
    gnutls-bin=3.* \
    iputils-ping=3:* \
    libapache2-mod-security2=2.* \
    libc6=2.* \
    libfreetype6-dev=2.* \
    libfreetype6=2.* \
    libgrpc++-dev=1.* \
    libicu-dev=72.* \
    libjpeg62-turbo-dev=1:2.* \
    libjpeg62-turbo=1:2.* \
    libpng-dev=1.6.* \
    libpng16-16=1.* \
    libpq-dev=15.* \
    libsqlite3-0=3.* \
    libxml2-dev=2.* \
    libxrender1=1:0* \
    libzip-dev=1.* \
    linux-libc-dev=6.* \
    net-tools=2.* \
    perl=5.* \
    xz-utils=5.* \
    unzip=6.* \
    vim=2:9.* \
    xfonts-75dpi=1:1.* \
    xfonts-base=1:1.* \
    xvfb=2:21.* \
    zip=3.* \
    zlib1g-dev=1:1.*

# Clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP Extensions
RUN docker-php-ext-configure zip && \
    docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j"$(nproc)" intl pgsql pdo pdo_pgsql opcache zip gd

# PHP Extensions (Opentelemetry)
RUN pecl install opentelemetry protobuf
RUN docker-php-ext-enable opentelemetry protobuf

# Install GRPC (pour OpenTeletry) > PECL installation is far too long, so install manually (@see https://stackoverflow.com/a/78683184)
RUN git clone --depth 1 -b v1.63.x https://github.com/grpc/grpc /tmp/grpc \
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