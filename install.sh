modules="accounts \
activity \
events \
friends \
registration \
search \
push.py"
status intertwine 2> /dev/null | grep "running" && stop intertwine
mkdir /usr/lib/python2.7/intertwine 2> /dev/null
touch /usr/lib/python2.7/intertwine/__init__.py

cp -R $modules /usr/lib/python2.7/intertwine/

mkdir -p /opt/intertwine/certs 2> /dev/null
cp newck.pem /opt/intertwine/certs/
cp intertwine /usr/bin/
cp intertwine.conf /etc/init/
start intertwine
