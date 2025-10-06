FROM debian:bullseye

#Updae and install req dependencies for the mariaDB container && 
#cleanup unnecessary files

#req dependencies for PHP-FPM
RUN apt-get update && \
    apt-get install -y php php-fpm php-mysql php-gd php-xml php-curl \
    php-mbstring curl tar \
    && rm -rf /var/lib/apt/lists/*

#wordpress port
EXPOSE 9000

#set the workdir as 
WORKDIR /var/www/html

#wordpress req dependencies
RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzf wordpress.tar.gz --strip-components=1 \
    && rm wordpress.tar.gz


#copy the init script from tools
COPY ./tools/init_wpress.sh /usr/local/bin/init_wpress.sh

#give exec permisions
RUN chmod +x /usr/local/bin/init_wpress.sh

ENTRYPOINT ["/usr/local/bin/init_wpress.sh"]
