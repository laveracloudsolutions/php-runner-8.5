# Utilisation de la version stable
FROM ghcr.io/laveracloudsolutions/php:8.5-apache-trixie

# Installation des dépendances système
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -qy \
    apache2 \
    ca-certificates \
    curl \
    bind9-dnsutils \
    expat \
    fontconfig \
    git \
    gnupg \
    gnutls-bin \
    iputils-ping \
    libapache2-mod-security2 \
    libc6 \
    libfreetype-dev \
    libfreetype6 \
    libgrpc++-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libjpeg62-turbo \
    libpng-dev \
    libpng16-16t64 \
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
    zlib1g-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 1. Extensions natives
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j"$(nproc)" intl pgsql pdo pdo_pgsql zip gd

# 2. Extensions PECL légères
RUN pecl install redis opentelemetry protobuf && \
    docker-php-ext-enable redis opentelemetry protobuf

# 3. Build RAPIDE de gRPC v1.78.x (Correction des chemins d'inclusion)
RUN git clone --depth 1 -b v1.78.x https://github.com/grpc/grpc /tmp/grpc && \
    cd /tmp/grpc && \
    git submodule update --init --recursive --depth 1 && \
    cd src/php/ext/grpc && \
    phpize && \
    # On force l'inclusion des headers du dépôt cloné pour trouver grpc/credentials.h
    CFLAGS="-I/tmp/grpc/include -I/tmp/grpc" ./configure --enable-grpc && \
    make -j"$(nproc)" && \
    make install && \
    docker-php-ext-enable grpc && \
    rm -rf /tmp/grpc

RUN a2enmod headers rewrite remoteip security2

RUN ln -snf /usr/share/zoneinfo/Europe/Paris /etc/localtime && echo "Europe/Paris" > /etc/timezone

EXPOSE 8080
WORKDIR /var/www/html

COPY ./config/php/php.ini /usr/local/etc/php/php.ini
COPY ./config/apache/VirtualHost.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/apache/apache2.conf /etc/apache2/apache2.conf
COPY ./config/apache/ports.conf /etc/apache2/ports.conf
COPY ./config/apache/mods-enabled/deflate.conf /etc/apache2/mods-enabled/deflate.conf