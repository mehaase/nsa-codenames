#!/bin/bash
#
# This assumes that you already have the code checked out
# at /opt/nsa-codenames.

if [[ $EUID -ne 0 ]]; then
    echo 'This script must be run as root.'
    exit 1
fi

export ROOT_PATH=/opt/nsa-codenames

# Security setup.
useradd -m nsa_codenames
chsh nsa_codenames -s /usr/sbin/nologin
passwd -l nsa_codenames
mkdir -p $ROOT_PATH/static/.webassets-cache
chown -R nsa_codenames:nsa_codenames \
         $ROOT_PATH/data \
         $ROOT_PATH/static/combined $ROOT_PATH/static/.webassets-cache

cp $ROOT_PATH/conf/local.ini.template $ROOT_PATH/conf/local.ini
flask_key=`cat /dev/urandom | head -c 30 | base64`
sed --in-place "s:##FLASK_SECRET_KEY##:$flask_key:" $ROOT_PATH/conf/local.ini

# Dependencies
apt-get install `cat $ROOT_PATH/install/apt-dependencies.txt`
pip3 install -r $ROOT_PATH/install/python-dependencies.txt

# Dart/Angular setup.
cd /opt
DART_URL='https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip'
curl $DART_URL > dart-sdk.zip
unzip dart-sdk.zip
find /opt/dart-sdk/bin/ -type f -executable -exec ln -s {} /usr/local/bin/ \;
cd $ROOT_PATH/static/dart
pub build

# Node setup.
ln -s /usr/bin/nodejs /usr/local/bin/node

# Database setup.
mysql_user='nsa_codenames'
mysql_pass=`cat /dev/urandom | head -c 12 | base64`
mysql_super_user='nsa_codenames_su'
mysql_super_pass=`cat /dev/urandom | head -c 12 | base64`

echo 'Enter the MySQL root password: '
read mysql_root_pass
echo "CREATE SCHEMA nsa_codenames CHARACTER SET utf8 COLLATE utf8_unicode_ci" \
     | mysql -u root -p$mysql_root_pass;
echo "GRANT ALL ON nsa_codenames.* TO nsa_codenames_su@localhost " \
     " IDENTIFIED BY '$mysql_super_pass'" | mysql -u root -p$mysql_root_pass;
echo "GRANT SELECT, INSERT, UPDATE, DELETE ON nsa_codenames.* " \
     "TO nsa_codenames@localhost IDENTIFIED BY '$mysql_pass'" \
     | mysql -u root -p$mysql_root_pass;

sed --in-place "s:##DATABASE_USERNAME##:$mysql_user:" \
    $ROOT_PATH/conf/local.ini
sed --in-place "s:##DATABASE_PASSWORD##:$mysql_pass:" \
    $ROOT_PATH/conf/local.ini
sed --in-place "s:##DATABASE_SUPER_USERNAME##:$mysql_super_user:" \
    $ROOT_PATH/conf/local.ini
sed --in-place "s:##DATABASE_SUPER_PASSWORD##:$mysql_super_pass:" \
    $ROOT_PATH/conf/local.ini

python3 $ROOT_PATH/bin/database.py build

# Generate dummy TLS certificate.
make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/server.crt

# Apache setup.
a2enmod headers rewrite ssl wsgi
ln -s $ROOT_PATH/install/apache.conf \
    /etc/apache2/sites-available/nsa-codenames.conf
a2ensite nsa-codenames
a2dissite 000-default
service apache2 reload

# Cron setup.
cp $ROOT_PATH/install/crontab.txt /etc/cron.d/nsa_codenames

# Reminders.
echo "Don't forget to: "
echo "  1. Put the hostname in /etc/hosts and /etc/hostname."
echo "  2. Configure AWS keys for backup."
echo "  3. Configure Twitter API Access."
echo "  4. Install real TLS certificate."
