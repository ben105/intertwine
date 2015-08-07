import psycopg2

dbname = "intertwine"
host = "localhost"
user = "intertwine"
password = "intertwine"


def connect():
	try:
		conn = psycopg2.connect("dbname=%s host=%s user=%s password=%s" % (dbname, host, user, password))
		cur = conn.cursor()
		cur.connection.autocommit = True
	except Exception as exc:
		print "Failed to connect to database"
		print exc
		return None
	return cur
