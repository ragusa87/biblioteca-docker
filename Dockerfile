FROM php:8.2-apache-bookworm

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/home/.composer
RUN mkdir -p /home/.composer
RUN printf "deb http://http.us.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list.d/nonfree.list

# npm is included in nodejs, see https://askubuntu.com/a/1432138
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    cron \
    curl \
    dma  \
    ghostscript \
    git \
    mariadb-client \
    nodejs \
    openssl \
    p7zip-full \
    sudo \
    supervisor \
    tesseract-ocr \
    unrar \
    unzip \
    vim \
    wget  \
    zip \
    && rm -rf /var/lib/apt/lists/*

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

# Install kepubify (from https://github.com/linuxserver/docker-calibre-web/blob/master/Dockerfile)
RUN \
    if [ -z ${KEPUBIFY_RELEASE+x} ]; then \
    KEPUBIFY_RELEASE=$(curl -sX GET "https://api.github.com/repos/pgaskin/kepubify/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /usr/bin/kepubify -L \
    https://github.com/pgaskin/kepubify/releases/download/${KEPUBIFY_RELEASE}/kepubify-linux-64bit && \
    chmod +x /usr/bin/kepubify

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

RUN mkdir -p /var/www/.npm && chown -R $UID:$GID /var/www/.npm

USER www-data

WORKDIR /var/www/html
CMD ["docker-php-entrypoint", "apache2-foreground"]
