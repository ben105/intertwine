import psycopg2
import os

def init(cur, sqlfile):
	"""Initializes the database with the SQL script provided
	via the pathname sqlfile.

	Keyword Arguments:
		cur - psycopg2 database cursor
		sqlfile - the path to the SQL script file

	Raises:
		ValueError if the file cannot be found, or if the cursor
		is an invalid cursor.
	"""
	if not cur:
		raise ValueError('invalid cursor provided')
	if not os.path.exists(sqlfile):
		raise ValueError('%s file could not be found' % sqlfile)
	cur.execute(open(sqlfile).read())
	cur.connection.commit()

def stop(cur, db_name='testdb'):
	cur.execute('DROP DATABASE {};'.format(db_name))
	cur.connection.commit()
	cur.connection.close()

def start(db_name='testdb'):
	"""This function will create a new database with the name
	provided by the argument.

	Keyword arguments:
		db_name - name of the test database
				  (default name is "testdb")

	Returns:
		psycopg2 database cursor
	"""
	# Sign in with intertwine user, who does have permission
	# to create databases.
	conn = psycopg2.connect('dbname=intertwine host=intertwine.cntms98hv39g.us-west-2.rds.amazonaws.com user=intertwine password=intertwine')
	cur = conn.cursor()
	cur.connection.autocommit = True
	try:
		cur.execute('CREATE DATABASE {};'.format(db_name,))
	except psycopg2.ProgrammingError as exc:
		cur.execute('DROP DATABASE {};'.format(db_name,))
		cur.connection.commit()
		cur.execute('CREATE DATABASE {};'.format(db_name,))

	# Drop the previous connection and reconnect with the new database.
	conn.close()
	cur.close()
	conn = psycopg2.connect('dbname={} host=intertwine.cntms98hv39g.us-west-2.rds.amazonaws.com user=intertwine password=intertwine'.format(db_name))
	cur = conn.cursor()
	cur.connection.autocommit = True
	
	# Initialize the database with the script to build the schema.
	sqlscript = 'schema.sql'
	sqlscript_path = os.path.join('/home/calgrove/intertwine/db', sqlscript)
	init(cur, sqlscript_path)
	
	return cur
