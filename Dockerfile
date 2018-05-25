FROM php:7.0-fpm

RUN apt-get update \
  && apt-get install -y \
    cron \
    gnupg \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev \
    gettext \
    msmtp \
    git \
    vim \
    nodejs

RUN docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
    gd \
    intl \
    mbstring \
    mcrypt \
    pdo_mysql \
    xsl \
    zip \
    soap \
    bcmath \
    mysqli \
    opcache \
    pcntl

RUN pecl install -o -f xdebug-2.5.0
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini;

# Configuration files
COPY etc /usr/local/etc/php/conf.d/
COPY etc/msmtprc.template /etc/msmtprc.template

# Copy in Entrypoint file & Magento installation script
COPY bin bin/magento-install bin/magento-configure /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-configure /usr/local/bin/magento-install /usr/local/bin/magento-configure

# Composer
RUN  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www

RUN rm -rf html && mkdir pub && mkdir var && mkdir -p app/etc
