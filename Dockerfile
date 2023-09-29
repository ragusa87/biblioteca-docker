FROM php:8.2-apache-bookworm

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /home/.composer
RUN mkdir -p /home/.composer
RUN printf "deb http://http.us.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list.d/nonfree.list
RUN  apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    # Tools
    vim git curl cron wget zip unzip \
    # other
    apt-transport-https \
    dma  \
    p7zip-full \
    build-essential \
    ca-certificates \
    mariadb-client \
    openssl \
    supervisor \
    tesseract-ocr \
    nodejs \
    ghostscript \
    unrar \
    npm \
    sudo && rm -rf /var/lib/apt/lists/*

# auto install dependencies and remove libs after installing ext: https://github.com/mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/


RUN install-php-extensions \
    opcache \
    intl \
    pdo_mysql \
    zip \
    bcmath \
    exif \
    gd \
    imagick \
    @composer


RUN apt-get purge -y --auto-remove
RUN a2enmod rewrite

COPY docker/001-biblioteca.conf /etc/apache2/sites-enabled/001-biblioteca.conf
RUN touch /var/www/.bash_history && chmod 777 /var/www/.bash_history
# Run from unprivileged port 8080 only
RUN sed -e 's/Listen 80/Listen 8080/g' -i /etc/apache2/ports.conf

COPY ./docker/dma.conf /etc/dma/dma.conf
COPY ./docker/biblioteca.ini /usr/local/etc/php/conf.d/biblioteca.ini
COPY ./docker/policy.xml /etc/ImageMagick-6/policy.xml

ARG UNAME=www-data
ARG UGROUP=www-data
ARG UID=1000
ARG GID=1000
RUN usermod  --uid $UID $UNAME
RUN groupmod --gid $GID $UGROUP

USER www-data

WORKDIR /var/www/html
CMD ["docker-php-entrypoint", "apache2-foreground"]
