#!/bin/sh

cur_dir=`dirname "$0"`
src_dir="${cur_dir}/../src"
lib_dir="${cur_dir}/../lib"


# If Intertwine is currently running, shut it down.
status intertwine 2> /dev/null | grep "running" && stop intertwine

rm -rf /usr/lib/python2.7/intertwine 2> /dev/null
rm -rf /opt/intertwine/* 2> /dev/null

# Create the intertwine parent directory.
mkdir -p /opt/intertwine 2> /dev/null
chown intertwine:intertwine /opt/intertwine
touch /opt/intertwine/__init__.py
ln -s /opt/intertwine/ /usr/lib/python2.7/intertwine 2> /dev/null

# Copy all the module containers into this 
# new parent directory.
cp -R "${src_dir}/." "${lib_dir}/." "${cur_dir}/../db/testdb.py" /opt/intertwine/
for f in `ls $src_dir`
do
	touch "/opt/intertwine/${f}/__init__.py"
done

# Certificates will be placed here.
mkdir -p /opt/intertwine/certs 2> /dev/null
cp ${cur_dir}/../newck4.pem /opt/intertwine/certs/

# Logs will be placed here.
mkdir -p /var/log/intertwine 2> /dev/null
chown intertwine:intertwine /var/log/intertwine
chmod 777 /var/log/intertwine

# Copy important files into the right place.
cp ${cur_dir}/../bin/intertwine /usr/bin/
cp ${cur_dir}/intertwine.conf /etc/init/

# Start the service!
start intertwine
