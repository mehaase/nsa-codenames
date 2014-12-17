# Apache setup.
a2enmod wsgi
cp ./apache.conf /etc/apache2/sites-available/nsa-codenames.conf
a2ensite nsa-codenames
a2dissite 000-default

# Security setup.
useradd nsa_codenames
