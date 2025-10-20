FROM debian:bookworm

# Install PHP, PHP-FPM, and MySQL client
RUN apt-get update && \
    apt-get install -y php php-fpm php-mysql php-gd php-xml php-curl \
    php-mbstring curl tar mariadb-client \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 9000

WORKDIR /var/www/html

# Download and extract WordPress
RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf wordpress.tar.gz --strip-components=1 && \
    rm wordpress.tar.gz

COPY ./tools/init_wpress.sh /usr/local/bin/init_wpress.sh
RUN chmod +x /usr/local/bin/init_wpress.sh

ENTRYPOINT ["/usr/local/bin/init_wpress.sh"]
