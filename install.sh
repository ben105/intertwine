# The below list of folders, are the Python module
# containers that we will want to copy into the 
# sites-enabled library path.
modules="accounts \
activity \
events \
friends \
registration \
search \
log \
push.py \
testdb.py"

# If Intertwine is currently running, shut it down.
status intertwine 2> /dev/null | grep "running" && stop intertwine

# Create the intertwine parent directory.
mkdir /usr/lib/python2.7/intertwine 2> /dev/null
touch /usr/lib/python2.7/intertwine/__init__.py

# Copy all the module containers into this 
# new parent directory.
cp -R $modules /usr/lib/python2.7/intertwine/

# Certificates will be placed here.
mkdir -p /opt/intertwine/certs 2> /dev/null

# Logs will be placed here.
mkdir -p /var/log/intertwine 2> /dev/null
chmod 777 /var/log/intertwine

# Copy important files into the right place.
cp newck.pem /opt/intertwine/certs/
cp intertwine /usr/bin/
cp intertwine.conf /etc/init/

# Start the service!
start intertwine
