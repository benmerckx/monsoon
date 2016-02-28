FROM debian:jessie

RUN echo "deb http://httpredir.debian.org/debian stretch main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -t stretch install -y apache2 haxe libapache2-mod-neko && apt-get clean

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN a2enmod rewrite
RUN a2enmod neko

RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]