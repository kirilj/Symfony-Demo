#!/bin/sh
set -e

cd /usr/src/app

# Run the importmap installation
php bin/console importmap:install

# Start Apache in the foreground 
exec apache2-foreground "$@"
