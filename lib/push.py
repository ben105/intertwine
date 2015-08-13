import socket, ssl, json, struct
import binascii
import os
import psycopg2

from intertwine import devices


def name(ctx):
	try:
		cur.execute("SELECT first, last FROM accounts WHERE id=%s", (user_id,))
	except Exception as exc:
		print("Failed trying to get name for %d" % user_id)
		return None
	row = cur.fetchone()
	return "{} {}".format(row[0], row[1])

def push_notification(ctx, msg):
	deviceToken = devices.get_token(ctx)
	if not deviceToken:
		logging.error(
			'error getting device token for user %d\n \
			Push notification won\'t be sent.', ctx.user_id)
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
