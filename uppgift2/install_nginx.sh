#!/bin/bash
# set -o errexit
# Let's install nginx

# Check that the script is run by root
if [ $(whoami) != root ]; then
        echo "You are running as $(whoami). Please run as root or use sudo."
        exit
fi

# Install nginx
# Expl. I check if nginx is installed and sending stderr to null.
# Then I pipe the output from dpkg-query to grep and count the number of occurences of the word not-installed, if that equals 1,  I install nginx.
if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "installed") -eq 0 ]
then
echo "Installing Nginx..."
apt-get -q -y update > /dev/null 
apt-get -q -y install nginx > /dev/null
fi

# Is nginx enabled and running?
# Expl. I use systemctl to verify if nginx is enabled and activated. It seems that in Ubuntu this will be the case but that can change in the future.

loaded=$(systemctl is-enabled nginx)
active=$(systemctl is-active nginx)

if [ $loaded != enabled ]
then
	echo "Enabling Nginx..."
	systemctl -q enable nginx
fi
if [ $active != active ]
then
	echo "Starting Nginx..."
	systemctl -q start nginx

fi

# Enabling firewall
# Expl. A good practice to always have the firewall running.
# And I'm adding rules to allow ssh and http.
if [ $(ufw status | grep -c "Status: inactive") -eq 1 ]
then
	echo "Enabling the firewall..."
	yes | ufw enable 2>&1 > /dev/null
	ufw allow ssh
	ufw allow http
fi

# Add a new default homepage.
# Expl. I'm creating this by using heredoc.
wwwdir=/var/www/html
echo "Creating a new default homepage..."
cat << EOF > $wwwdir/index.html
<!DOCTYPE html>
<html>
<body>
</br>
<h1>Martin Hellstrom</h1>
</body>
</html>
EOF
echo "Done."

# Verify that the default homepage has been updated.
echo "Verifing that the new homepage is accessible..."
sleep 1
if [ $(curl -s http://localhost:80 | grep -c "Martin") -eq 1 ]
then
	echo "It works. You have a new default webpage served by Nginx."
else
	echo "Something went wrong.\nInvestigate the directory $wwwdir and search for a file called index.html"
fi

