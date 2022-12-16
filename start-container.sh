#!/bin/bash
composer install
chown -R docker_app_user:docker_app_user storage bootstrap vendor
chmod -R ug+rwx storage bootstrap vendor
service supervisor start
service cron start
php-fpm
