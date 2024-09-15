# Stage 1: Build Stage (for compiling necessary extensions)
FROM php:fpm-alpine3.20 AS builder

# Install dependencies for building extensions
RUN apk add --no-cache autoconf libpng-dev zip libzip-dev unzip git curl \
    build-base freetype-dev jpeg-dev libjpeg-turbo-dev linux-headers supervisor

# Install and enable PHP extensions
RUN docker-php-ext-install pdo_mysql zip exif pcntl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Install Redis and Igbinary extensions
RUN curl https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar --output pickle.phar \
    && chmod +x pickle.phar \
    && mv pickle.phar /usr/bin/pickle \
    && pecl install igbinary \
    && pecl install redis \
    && docker-php-ext-enable igbinary redis \
    && rm -f /usr/bin/pickle

# Install Xdebug and PCOV for development, remove in production if needed
RUN pecl install xdebug pcov \
    && docker-php-ext-enable xdebug pcov

RUN docker-php-ext-install opcache

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer clear-cache

# Stage 2: Production Stage
FROM php:fpm-alpine3.20

#Install runtime dependencies only
RUN apk add --no-cache freetype libpng jpeg libjpeg-turbo libzip

# Copy necessary files from the build stage
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=builder /usr/local/bin/composer /usr/local/bin/composer

# Set up user and permissions
RUN addgroup -S dev \
    && adduser -u1000 dev -h /home/dev -s /bin/sh -S -G dev \
    && adduser www-data dev \
    && chown -R dev:dev /home/dev

ARG GL_TOKEN

# Set composer token as dev user
USER dev
RUN composer config --global gitlab-token.gitlab.digitaltolk.net "$GL_TOKEN"
USER root

# Expose PHP-FPM port
EXPOSE 9000

# Start the container
CMD ["php-fpm"]
