import psycopg2
import time
import datetime
import hashlib
import random

SERVER_ERROR = "An error has occured on the Intertwine server, please try again later."

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
	err = None
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
		password_salt)
		VALUES
		(%s,%s,%s,%s,%s)
		RETURNING id;
	"""
	try:
		db_cursor.execute(query, (email, first, last, hashed_password, salt))
	except Exception as exc:
		print exc
		err = SERVER_ERROR
		return err
	account_id = db_cursor.fetchone()[0]
	print "Finished creating brand new account for %s %s" % (first, last)	
	return err

def sign_in_facebook(facebook_id, first, last):
	err = None
	# Bail early if there already exists a facebook account
	# with this Facebook ID
	query = """
		SELECT id, password
		FROM accounts
		WHERE facebook_id=%s;
	"""
	rows = []
	try:
		db_cursor.execute(query, (facebook_id,))
		rows = db_cursor.fetchall()
	except:
		err = SERVER_ERROR
	if len(rows):
		print("Account already exists")
		session_block = get_response_block(account_id, hashed_password, err)
		return session_block
	
	salt = random_salt(16)
	print "Random salt generated %s" % salt
	hashed_password = get_hash_password(facebook_id, salt)
	print "Hashed password %s" % hashed_password
	
	query = """
		INSERT INTO accounts
		(facebook_id,
		first, 
		last,
		password,
		password_salt)
		VALUES
		(%s, %s, %s);
	"""
	try:
		db_cursor.execute(query, (facebook_id, first, last, hashed_password, salt))
	except:
		err = SERVER_ERROR
		session_block(error=err)
		return session_block
	account_id = db_cursor.fetchone()[0]
	print "Finished creating brand new account for %s %s" % (first, last)
	print "Facebook ID {}".format(facebook_id)
	session_key = get_session_key(account_id, hashed_password)
	session_block = get_response_block(session=session_key, error=err)
	return session_block
	
def sign_in(email, password):
	err = None
	try:
		db_cursor.execute("SELECT password, password_salt, id FROM accounts WHERE email=%s", (email,))
	except:
		err = SERVER_ERROR
		session_block = get_response_block(error=err)
		return session_block
	rows = db_cursor.fetchall()
	if len(rows):
		hashed_password = rows[0][0]
		salt = rows[0][1]
		account_id = str(rows[0][2])
		print "Hashed password received: " + hashed_password
		print "Salt: " + salt
		print "Account ID: " + account_id
		password_attempt = get_hash_password(password, salt)
		if password_attempt == hashed_password:
			session_block = get_response_block(account_id, hashed_password)
			return session_block
		else:
			# Incorrect password
			err = "Invalid login credentials"
	else:
		# Incorrect email
		err = "Invalid login credentials."
	session_block = get_response_block(account_id, hashed_password, err)
	return session_block


def get_response_block(account_id=None, session=None, error=None):
	if (not session or not account_id) and not error:
		# There is no session or error? Uh-oh...
		error = SERVER_ERROR
	if error:
		# Create JSON with error
		json = {
			'error':error
		}
	else:
		json = {
			'error':None,
			'session_key':session,
			'account_id':account_id
		}
	if not json:
		json = {
			'error':SERVER_ERROR
		}
	return json
	
