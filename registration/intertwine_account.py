import psycopg2
import time
import datetime
import hashlib
import random

db_cursor = None
def set_database_cursor(cursor):
	global db_cursor
	db_cursor = cursor

def get_now_timestamp():
	t = time.time()
	return datetime.datetime.fromtimestamp(t).strftime('%Y-%m-%d %H:%M:%S')

def random_salt(salt_len):
	alphanumeric = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	chars = list()
	for i in range(salt_len):
		chars.append(random.choice(alphanumeric))
	return "".join(chars)


def get_hash_password(password, salt):
	return hashlib.sha256(password + salt).hexdigest()

def create_account_email(email, first, last, password):
	salt = random_salt(16)
	print "Random salt generated %s" % salt
	hashed_password = get_hash_password(password, salt)
	print "Hashed password %s" % hashed_password
	created_date = get_now_timestamp()
	query = """
		INSERT INTO accounts
		(email,
		first,
		last,
		password,
		password_salt,
		created_date)
		VALUES
		(%s,
		%s,
		%s,
		%s,
		%s,
		%s);
	"""
	try:
		db_cursor.execute(query, (email, first, last, hashed_password, salt, created_date))
	except Exception as exc:
		return str(exc)
	print "Completed!"
	print "Finished creating brand new account for %s %s" % (first, last)	
	return None

def create_account_facebook(facebook_id, first, last, password):
	salt = random_salt(16)
	hashed_password = get_hash_password(password, salt)
	
def sign_in(email, password):
	try:
		db_cursor.execute("SELECT password, password_salt FROM accounts WHERE email=%s", (email,))
	except Exception as exc:
		print exc
		return False
	rows = db_cursor.fetchall()
	print "Row count:"
	print len(rows)
	if len(rows):
		hashed_password = rows[0][0]
		salt = rows[0][1]
		print "Hashed password received: " + hashed_password
		print "Salt: " + salt
		password_attempt = get_hash_password(password, salt)
		if password_attempt == hashed_password:
			return True
	else:
		return False



def create_account():
	pass
