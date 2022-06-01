FROM php:8.1-fpm
 
# Set working directory
WORKDIR /var/www/html/
 
# Install dependencies for the operating system software
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    libzip-dev \
    unzip \
    git \
    libonig-dev \
    curl
 
# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Install extensions for php
RUN docker-php-ext-install pdo_mysql mbstring zip exif
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd
 
# Install composer (php package manager)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
 
# Copy existing application directory contents to the working directory
# COPY . /var/www/html
 
# Assign permissions of the working directory to the www-data user
# RUN chown -R www-data:www-data \
#         /var/www/html/storage \
#         /var/www/html/bootstrap/cache
# RUN composer install
RUN apt-get update && apt-get install supervisor cron -y
COPY ./start-container.sh /usr/bin/start-container
RUN chmod +x /usr/bin/start-container

RUN useradd -u1000 docker_app_user
RUN adduser www-data docker_app_user
RUN mkdir /home/docker_app_user
RUN chown -R docker_app_user:docker_app_user /home/docker_app_user

RUN echo "* * * * * root php /var/www/html/artisan schedule:run >> /var/www/html/storage/logs/cron.log 2>&1" >> /etc/crontab

# Expose port 9000 and start php-fpm server (for FastCGI Process Manager)
EXPOSE 9000
# CMD [ "php-fpm" ]
ENTRYPOINT ["start-container" ]
