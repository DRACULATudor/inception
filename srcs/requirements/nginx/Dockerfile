FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*



#https port
EXPOSE 443

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
 
