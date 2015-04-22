import socket, ssl, json, struct
import binascii
import os
import psycopg2

def device_token(cur, user_id):
	token = None
	try:
		cur.execute("SELECT token FROM device_tokens WHERE accounts_id=%s;", (user_id,))
	except:
		return token
	row = cur.fetchone()
	return row[0]

def name(cur, user_id):
	try:
		cur.execute("SELECT first, last FROM accounts WHERE id=%s", (user_id,))
	except Exception as exc:
		print("Failed trying to get name for %d" % user_id)
		return None
	row = cur.fetchone()
	return "{} {}".format(row[0], row[1])

def push_notification(cur, user_id, msg):
	deviceToken = str(device_token(cur, user_id))
	if not deviceToken:
		print("Error getting device token!")
		return
	thePayLoad = {
	     'aps': {
	          'alert':msg,
	          'sound':'default'
	          }
	     }
	theCertfile = '/opt/intertwine/certs/newck.pem'
	theHost = ( 'gateway.sandbox.push.apple.com', 2195 )
	data = json.dumps( thePayLoad )
	# Format the data
	theFormat = '!BH32sH%ds' % len(data)
	# Put everything together
	theNotification = struct.pack( theFormat, 0, 32, deviceToken, len(data), data )
	# Create the SSL socket
	ssl_sock = ssl.wrap_socket( socket.socket( socket.AF_INET, socket.SOCK_STREAM ), certfile = theCertfile )
	ssl_sock.connect( theHost )
	ssl_sock.write( theNotification )
	ssl_sock.close()
