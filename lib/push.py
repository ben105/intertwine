import socket, ssl, json, struct
import binascii
import os
import psycopg2
import logging

from intertwine import devices

import urllib2, httplib
import urllib

class HTTPSClientAuthHandler(urllib2.HTTPSHandler):
    def __init__(self, key, cert):
        urllib2.HTTPSHandler.__init__(self)
        self.key = key
        self.cert = cert

    def https_open(self, req):
        # Rather than pass in a reference to a connection class, we pass in
        # a reference to a function which, for all intents and purposes,
        # will behave as a constructor
        return self.do_open(self.getConnection, req)

    def getConnection(self, host, timeout=300):
        return httplib.HTTPSConnection(host, key_file=self.key, cert_file=self.cert)





# There are certain actions we might want the iOS
# application to take.
SHOW_EVENT_COMMENTS = 0      # implicit jump-to
SHOW_EVENT = 1		     # implicit jump-to
JUMP_TO = 2



RESP_FORMAT = (
        '!' # network big-endian
        'B' # command
        'B' # status
        'I' # indentifier
)


def name(ctx):
	try:
		cur.execute("SELECT first, last FROM accounts WHERE id=%s", (user_id,))
	except Exception as exc:
		print("Failed trying to get name for %d" % user_id)
		return None
	row = cur.fetchone()
	return "{} {}".format(row[0], row[1])

def save_notification(ctx, user_id, msg, payload, deviceToken=None):
	query = """
	INSERT INTO
		notifications
	(notifier_id, message, payload, device_token)
	VALUES (%s, %s, %s, %s);
	"""
	try:
		ctx.cur.execute(query, (user_id, msg, json.dumps(payload).strip(), deviceToken))
	except Exception as exc:
		logging.error('exception raise when trying to save notification:\n%s', str(exc))


def push_notification2(ctx, user_id, msg, notifInfo=None):
	actionEnum = None
	event_id = None
	if notifInfo is not None:
		actionEnum = notifInfo.get('action')
		event_id = notifInfo.get('event_id')

	deviceTokens = devices.get_token(ctx.cur, user_id)
	if not deviceTokens:
		logging.error(
			'error getting device token for user %d\n \
			Push notification won\'t be sent.', user_id)
		return

	try:
		ctx.cur.execute("SELECT facebook_id FROM accounts WHERE id=%s", (ctx.user_id,))
	except Exception as exc:
		logging.error('error getting Facebook ID from the notifier %d\n%s', ctx.user_id, str(exc))
		return
	facebook_id = ctx.cur.fetchone()[0]

	thePayLoad = {
	     'aps': {
	          'alert':msg,
	          'sound':'default'
	          },
	     'notifier_id':facebook_id,
	     'event_id':event_id,
	     'action': actionEnum # This is a number, based on values above.
	     }
#	data = json.dumps( thePayLoad )
	data = urllib.urlencode(thePayLoad)
	opener = urllib2.build_opener(HTTPSClientAuthHandler('/opt/intertwine/certs/newck4.pem', '/opt/intertwine/certs/newck4.pem') )
	opener.addheaders = [('apns-priority', 10), ('content-length', len(data))]
	urllib2.install_opener(opener)
	resp = urllib2.urlopen("https://api.development.push.apple.com/3/device/3a2cbe5e8c22c3774c1d90fbb5533ac2fc54744280a9e03bc420b5f935319f13", data)
	#response = opener.open("https://api.development.push.apple.com")
	print resp.read()
	

def push_notification(ctx, user_id, msg, notifInfo=None):
	actionEnum = None
	event_id = None
	if notifInfo is not None:
		actionEnum = notifInfo.get('action')
		event_id = notifInfo.get('event_id')

	deviceTokens = devices.get_token(ctx.cur, user_id)
	if not deviceTokens:
		logging.error(
			'error getting device token for user %d\n \
			Push notification won\'t be sent.', user_id)
		return

	try:
		ctx.cur.execute("SELECT facebook_id FROM accounts WHERE id=%s", (ctx.user_id,))
	except Exception as exc:
		logging.error('error getting Facebook ID from the notifier %d\n%s', ctx.user_id, str(exc))
		return
	facebook_id = ctx.cur.fetchone()[0]

	thePayLoad = {
	     'aps': {
	          'alert':msg,
	          'sound':'default'
	          },
	     'notifier_id':facebook_id,
	     'event_id':event_id,
	     'action': actionEnum # This is a number, based on values above.
	     }
	theCertfile = '/opt/intertwine/certs/newck4.pem'
	theHost = ( 'gateway.sandbox.push.apple.com', 2195 )
	data = json.dumps( thePayLoad )
	# Format the data
	theFormat = '!BH32sH%ds' % len(data)
	# Create the SSL socket
	ssl_sock = ssl.wrap_socket( socket.socket( socket.AF_INET, socket.SOCK_STREAM ), certfile = theCertfile )
	ssl_sock.connect( theHost )

	save_notification(ctx, user_id, msg, thePayLoad)
	
	for deviceToken in deviceTokens:
		# Put everything together
		theNotification = struct.pack( theFormat, 0, 32, str(deviceToken), len(data), data )
		ssl_sock.write( theNotification )
		#resp = ssl_sock.read()
		#print(resp)
		#if resp:
		#	respFormatted = struct.unpack(RESP_FORMAT, str(resp))
		#	print(respFormatted)

		# Let's store the notificaiton history now, since we are assuming
		# that we successfully wrote to the server.
		# However, that might not be the case. But either way, we can still
		# present it as a historical notification whether it was sent or not.


	ssl_sock.close()
