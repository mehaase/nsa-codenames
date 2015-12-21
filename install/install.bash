#!/bin/bash
#
# Run as root. (This script is not complete, yet. Consider it more of an
# installation guide than an installer script.)

export ROOT_PATH=/opt/nsa-codenames
export PYTHON_PATH=$ROOT_PATH/lib

# Git setup.
cd $ROOT_PATH/..
git clone https://github.com/mehaase/nsa-codenames.git

# Security setup.
useradd -m nsa_codenames
chsh nsa_codenames -s /bin/false
passwd -l nsa_codenames
mkdir -p $ROOT_PATH/static/.webassets-cache
chown -R nsa_codenames:nsa_codenames $ROOT_PATH/data $ROOT_PATH/static/combined $ROOT_PATH/static/.webassets-cache

# Don't forget to to set up hostname and /etc/hosts!

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
## Need to create MySQL root user first. Don't use "password" as your password!
echo "CREATE SCHEMA nsa_codenames CHARACTER SET utf8 COLLATE utf8_unicode_ci" | mysql -u root -ppassword;
echo "GRANT ALL ON nsa_codenames.* TO nsa_codenames@localhost IDENTIFIED BY 'password'" | mysql -u root -ppassword;
python3 $ROOT_PATH/bin/database.py build
## Edit the local.ini config file

# Apache setup.
a2enmod headers rewrite ssl wsgi
ln -s $ROOT_PATH/install/apache.conf /etc/apache2/sites-available/nsa-codenames.conf
cp $ROOT_PATH/install/server.crt /etc/apache2 # Dummy certificate!
cp $ROOT_PATH/install/server.key /etc/apache2 # Dummy key!
a2ensite nsa-codenames
a2dissite 000-default
service apache2 reload

# Cron setup.
cp $ROOT_PATH/install/crontab.txt /etc/cron.d/nsa_codenames
