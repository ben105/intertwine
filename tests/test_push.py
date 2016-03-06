import psycopg2
import optparse

from intertwine import context
from intertwine import push

host = 'intertwine.cntms98hv39g.us-west-2.rds.amazonaws.com'

parser = optparse.OptionParser()
parser.add_option("-u", "--user", dest="user_id", default=1,
                  help="the user ID", metavar="user_id")
parser.add_option("-f", "--first", dest="first", default='Ben',
                  help="the user's first name", metavar="first")
parser.add_option("-l", "--last", dest="last", default='Rooke',
                  help="the user's last name", metavar="last")
parser.add_option("-t", "--target", dest="target", default=1,
                  help="the ID of the person to send the push to", metavar="target")
parser.add_option("-m", "--message", dest="message", default="hello",
		  help="push message", metavar="message")
(options, args) = parser.parse_args()

class FalseRequest(object):
	def __init__(self, user_id=None, first='', last=''):
		self.headers = { 'user_id':user_id, 'first':first, 'last':last }

def FalseSecurityContext(cur, user_id=None, first='', last=''):
	request = FalseRequest(user_id, first, last)
	return context.SecurityContext(request, cur)

def main():
	conn = psycopg2.connect('dbname=intertwine host=%s user=intertwine password=intertwine' % host)
	cur = conn.cursor()
	ctx = FalseSecurityContext(cur, options.user_id, options.first, options.last)
	push.push_notification(ctx, options.target, options.message)

if __name__ == '__main__':
	main()
