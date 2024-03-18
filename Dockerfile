FROM php:8.2-apache

# Install system dependencies in a single RUN command to reduce layer count
# Clean up apt cache in the same layer to reduce image size
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libonig-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl mbstring zip pdo_mysql \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*


# Copying Composer from the official image to reduce the number of layers and size
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Environment variables for Composer and Symfony
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV SYMFONY_PARAMS_STD="--version=6.4.* --webapp"

# Installing Symfony CLI in a single layer and cleaning up in the same layer
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get install -y symfony-cli \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache
COPY apache.conf /etc/apache2/sites-available/000-default.conf

# Setting the working directory
WORKDIR /usr/src/app

# Copy application code
COPY . /usr/src/app

# Create cache and log directories if they don't exist and set proper permissions
RUN mkdir -p /usr/src/app/var/cache /usr/src/app/var/log && \
    chown -R www-data:www-data /usr/src/app/var/cache /usr/src/app/var/log

RUN composer install

# entrypoint script
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Expose port 80
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \  
 CMD curl -f http://localhost/ || exit 1