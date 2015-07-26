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
	if not os.path.exist(sqlfile):
		raise ValueError('SQL file could not be found')
	cur.execute(open(sqlfile).read())

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
	conn = psycopg2.connect('user=intertwine password=intertwine')
	cur = conn.cursor()
	cur.connection.autocommit = True
	cur.execute('CREATE DATABASE %s;', db_name)

	# Initialize the database with the script to build the schema.
	sqlscript = 'schema.sql'
	sqlscript_path = os.path.join(os.path.dirname(__file__), sqlscript)
	init(cur, sqlscript_path)
	
	return cur