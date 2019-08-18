FROM centos
MAINTAINER www.g6p.cn
RUN yum install -y httpd php php-gd php-mysql && \
    echo "<?php phpinfo() ?>" > /var/www/html/index.php
CMD ["/usr/sbin/httpd","-D","FOREGROUND"]
EXPOSE 80

