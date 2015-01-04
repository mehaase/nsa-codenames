ROOT_PATH=/usr/share/nsa-codenames

# Apache setup.
a2enmod wsgi
cp ./apache.conf /etc/apache2/sites-available/nsa-codenames.conf
a2ensite nsa-codenames
a2dissite 000-default

# Dart/Angular setup.
cd /opt
DART_URL='https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip'
curl $DART_URL > dart-sdk.zip
unzip dart-sdk.zip
find /opt/dart-sdk/bin/ -type f -executable -exec echo ln -s {} /usr/local/bin/ \;

# Node setup.
ln -s /usr/bin/nodejs /usr/local/bin/node

# Security setup.
useradd nsa_codenames
chown -R root:root $ROOT_PATH
chown -R nsa_codenames:nsa_codenames $ROOT_PATH/DATA

# Database setup.
echo "CREATE SCHEMA nsa_codenames CHARACTER SET utf8 COLLATE utf8_unicode_ci" | mysql -u root -ppassword;
