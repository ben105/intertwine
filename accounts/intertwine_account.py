import psycopg2
import time
import datetime
import hashlib
import random
import logging

SERVER_ERROR = "An error has occured on the Intertwine server, please try again later."

def get_now_timestamp():
	t = time.time()
	return datetime.datetime.fromtimestamp(t).strftime('%Y-%m-%d %H:%M:%S')

def random_salt(salt_len):
	if salt_len <= 0:
		logging.error('constructing random salt with an invlaid length value, %s', salt_len)
		raise ValueError
	alphanumeric = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	chars = list()
	for i in range(salt_len):
		chars.append(random.choice(alphanumeric))
	return "".join(chars)


def salt_and_hash(password, salt):
	if not password or not salt:
		logging.error('invalid values when trying to salt and hash (password %s, salt %s)', password, salt)
		raise ValueError
	return hashlib.sha256(password + salt).hexdigest()

def create_email_account(cur, email, first, last, password):
	if not email:
		logging.error('no email provided for creating an email account!')
		raise ValueError
	if not first or not last:
		logging.error('first or last name are missing (%s, %s)', first, last)
		raise ValueError
	if not password:
		logging.error('password is missing')
		raise ValueError
	err = None
	salt = random_salt(16)
	logging.debug('random salt generated for %s %s', first, last)
	hashed_password = salt_and_hash(password, salt)
	logging.debug('hashed password for %s %s', first, last)
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
		cur.execute(query, (email, first, last, hashed_password, salt))
	except Exception as exc:
		logging.error('exception raised while trying to create a new account for %s %s', first, last)
		err = SERVER_ERROR
		return err
	account_id = cur.fetchone()[0]
	logging.info('created a new account for %s %s', first, last)
	return err

def sign_in_facebook(cur, facebook_id, first, last):
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
		cur.execute(query, (facebook_id,))
		rows = cur.fetchall()
	except:
		err = SERVER_ERROR
	if len(rows):
		account_id = rows[0][0]
		hashed_password = rows[0][1]
		session_block = get_response_block(account_id, hashed_password, err)
		return session_block
	
	salt = random_salt(16)
	hashed_password = salt_and_hash(facebook_id, salt)
	
	query = """
		INSERT INTO accounts
		(facebook_id,
		first, 
		last,
		password,
		password_salt)
		VALUES
		(%s, %s, %s, %s, %s);
	"""
	try:
		cur.execute(query, (facebook_id, first, last, hashed_password, salt))
	except Exception as exc:
		logging.error('exception raised attempting to create a new Facebook account for %s %s', first, last)
		err = SERVER_ERROR
		session_block = get_response_block(error=err)
		return session_block
	account_id = cur.fetchone()[0]
	logging.info('created a new Facebook account for %s %s', first, last)
	session_key = get_session_key(account_id, hashed_password)
	session_block = get_response_block(session=session_key, error=err)
	return session_block
	
def sign_in(cur, email, password):
	err = None
	try:
		cur.execute("SELECT password, password_salt, id FROM accounts WHERE email=%s", (email,))
	except:
		logging.error('failed to sign in user with email %s', email)
		err = SERVER_ERROR
		session_block = get_response_block(error=err)
		return session_block
	rows = cur.fetchall()
	if len(rows):
		hashed_password = rows[0][0]
		salt = rows[0][1]
		account_id = str(rows[0][2])
		logging.debug('retrieved data to authorize %s', email)
		password_attempt = salt_and_hash(password, salt)
		logging.debug('hashing %s\'s password attempt'. email)
		if password_attempt == hashed_password:
			logging.debug('%s\'s password verified', email)
			session_block = get_response_block(account_id, hashed_password)
			return session_block
		else:
			# Incorrect password
			logging.debug('%s\'s password rejected', email)
			err = "Invalid login credentials"
	else:
		# Incorrect email
		logging.debug('%s is an invalid email address', email)
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
	
