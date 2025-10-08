#MARIADB

#bullseyes is the penultimate stable version of debian
FROM debian:bookworm

#Updae and install req dependencies for the mariaDB container && 
#cleanup unnecessary files

RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && rm -rf /var/lib/apt/lists/*
#MariaDB port
EXPOSE 3306

COPY ./tools/init_mariaDB.sh /usr/local/bin/init_mariaDB.sh
RUN chmod +x /usr/local/bin/init_mariaDB.sh

#RUN mkdir -p /run/secrets
#call the init script for mariadb databae which injects the pass dincamicaly and than constantly runs 
#CMD ["mysqld"]
ENTRYPOINT ["/usr/local/bin/init_mariaDB.sh"]
