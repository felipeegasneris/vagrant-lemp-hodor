#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

sudo aptitude update -q

# Force a blank root password for mysql
echo "mysql-server mysql-server/root_password password " | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password " | debconf-set-selections

# Install mysql, nginx, php5-fpm
sudo aptitude install -q -y -f mysql-server mysql-client nginx php5-fpm

# Install commonly used php packages
sudo aptitude install -q -y -f php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt  php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl

sudo rm /etc/nginx/sites-available/eclass
sudo touch /etc/nginx/sites-available/eclass

sudo cat >> /etc/nginx/sites-available/eclass <<'EOF'
server {
    listen 80;
    root /home/vagrant/code/eclass;
    index index.php index.html;

    # Make site accessible from http://localhost/
    server_name *.v6.local *.v6.test *.platbe.test *.platbe.local;


    location = /check.txt {
       empty_gif;
       access_log off;
    }

    location ~ /\.ht {
        deny  all;
    }

    location ~ \.ctp$ {
        deny  all;
    }

    location / {
        client_body_buffer_size    128K;
        client_max_body_size       1000M;
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files      $uri = 404;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;

    }

    client_max_body_size 100M;
}

server {
    listen 80;
    root /home/felipe/eclass/blog;
    index index.php index.html;

    # Make site accessible from http://localhost/
    server_name blog.eclass.local;

    location = /check.txt {
       empty_gif;
       access_log off;
    }

    location ~ /\.ht {
        deny  all;
    }

    location ~ \.ctp$ {
        deny  all;
    }

    location / {
        client_body_buffer_size    128K;
        client_max_body_size       1000M;
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files      $uri = 404;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    client_max_body_size 100M;
}

server {
    listen 80;
    default_type  application/octet-stream;

    root /home/vagrant/code/eclass/static;
    index index.html index.htm;

    add_header Access-Control-Allow-Origin *;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';

    # Make site accessible from http://localhost/
    server_name static.v6.local static.v6.test;



    location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
        expires 1d;
        add_header Pragma public;
        add_header Cache-Control "public";
    }

    location ~* \.pdf {
        if ($http_user_agent ~ "Googlebot") {
            return 403;
        }

        if ($http_referer ~ "google") {
            return 403;
        }
    }

    location ~* \.(eot|otf|ttf|woff|html)$ {
        add_header Access-Control-Allow-Origin *;
        add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
    }

    location ^~  /vendors/tiny_upload {
        rewrite ^/vendors/tiny_upload(/.*)$ /tiny_upload$1 last;
    }

    location /munin {
       auth_basic      "Stats";
       auth_basic_user_file    htpasswd;
       expires epoch;
   }

   error_page 405 =200 $uri;

}
EOF

sudo rm /etc/nginx/sites-available/default
sudo touch /etc/nginx/sites-available/default

sudo cat >> /etc/nginx/sites-available/default <<'EOF'
server {
  listen   80;

  root /usr/share/nginx/html;
  index index.php index.html index.htm;

  # Make site accessible from http://localhost/
  server_name _;

  location / {
    # First attempt to serve request as file, then
    # as directory, then fall back to index.html
    try_files $uri $uri/ /index.html;
  }

  location /doc/ {
    alias /usr/share/doc/;
    autoindex on;
    allow 127.0.0.1;
    deny all;
  }

  # redirect server error pages to the static page /50x.html
  #
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/nginx/html;
  }

  # pass the PHP scripts to FastCGI server listening on /tmp/php5-fpm.sock
  #
  location ~ \.php$ {
    try_files $uri =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_index index.php;
    include fastcgi_params;
  }

  # deny access to .htaccess files, if Apache's document root
  # concurs with nginx's one
  #
  location ~ /\.ht {
    deny all;
  }

  ### phpMyAdmin ###
  location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
      client_max_body_size 4M;
      client_body_buffer_size 128k;
      try_files $uri =404;
      root /usr/share/;

      # Point it to the fpm socket;
      fastcgi_pass unix:/var/run/php5-fpm.sock;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      include /etc/nginx/fastcgi_params;
    }

    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)) {
      root /usr/share/;
    }
  }
  location /phpMyAdmin {
    rewrite ^/* /phpmyadmin last;
  }
  ### phpMyAdmin ###
}
EOF



sudo touch /usr/share/nginx/html/info.php
sudo cat >> /usr/share/nginx/html/info.php <<'EOF'
<?php phpinfo(); ?>
EOF

sudo aptitude install -q -y -f phpmyadmin

sudo service nginx restart

sudo service php5-fpm restart
