import psycopg2
import time
import datetime
import hashlib
import random
import logging
import intertwine.response
import intertwine.strings as strings


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
	"""When the user tries to create an email account, we
	must verify that they have entered correct information.
	We verify this on the server side, because otherwise a 
	malicious user could circumvent the app and write their own 
	request (bypassing checks).

	Keyword arguments:
	  cur - cursor to the database
	  email - new email address
	  first - first name
	  last - last name
	  password - new password 

	Returns:
	  Python dictionary containing success status, error and
	  error codes, and optional payload.
	"""

	if not email:
		logging.error('no email provided for creating an email account!')
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)
	if not first or not last:
		logging.error('first or last name are missing (first: %s, last: %s)', first, last)
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)
	if not password:
		logging.error('password is missing for %s %s (%s)', first, last, email)
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)

	# We want to create a random salt, and salt and hash the new password.
	# Then we can store the password "safely" in the database.
	salt = random_salt(16)
	logging.debug('random salt generated for %s %s', first, last)
	hashed_password = salt_and_hash(password, salt)
	logging.debug('hashed password for %s %s', first, last)
	query = """
		INSERT INTO accounts
			(email, first, last, password, password_salt)
		VALUES
			(%s,%s,%s,%s,%s)
		RETURNING id;
	"""
	try:
		cur.execute(query, (email, first, last, hashed_password, salt))
	except Exception as exc:
		logging.error('exception raised while trying to create a new account for %s %s (%s)', first, last, email)
		return intertwine.response.block(error=strings.strings.VALUE_ERROR, code=500)
	# We have succesfully created the account!
	logging.info('created a new account for %s %s (%s)', first, last, email)
	row = cur.fetchone()
	return intertwine.response.block(payload={
		'user_id': row[0]
	})


def sign_in_facebook(cur, facebook_id, first, last):
	"""This method should be envoked when the user is 
	signing on via a Facebook account. The actual 
	authentication and authorization is done on Facebook's
	side of things, but we can make sure that we create
	an accout for the user, if one does not already exist.

	Keyword arguments:
	  cur - cursor to the database
	  facebook_id - user's unique Facebook ID
	  first - the user's first name
	  last - the user's last name

	Returns:
	  Python dictionary containing success status, error and
	  error codes, and optional payload.
	"""
	if not facebook_id:
		logging.error('no Facebook ID provided for signing in via Facebook!')
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)
	if not first or not last:
		logging.error('first or last name are missing (first: %s, last: %s)', first, last)
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)

	# Let's see if we can find the user in our database with this
	# Facebook ID.
	try:
		cur.execute("SELECT id, password FROM accounts WHERE facebook_id=%s;", (facebook_id,))
	except:
		logging.error('exception raised trying to look up Facebook ID %s', facebook_id)
		return intertwine.response.block(error=strings.strings.VALUE_ERROR
strings.strings.VALUE_ERROR
strings.SERVER_ERROR, code=500)

	# Bail early if there already exists a facebook account
	# with this Facebook ID.
	rows = cur.fetchall()
	if len(rows):
		return intertwine.response.block()
	
	# The user's account does not exist for this Facebook ID,
	# so let's create one for them.
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
		return intertwine.response.block(error=strings.strings.VALUE_ERROR
strings.strings.VALUE_ERROR
strings.SERVER_ERROR, code=500)
	# We have successfully created a new Facebook account!	
	logging.info('created a new Facebook account for %s %s', first, last)
	return intertwine.response.block()
	

def sign_in_email(cur, email, password):
	"""This method should be envoked when the user is
	attempting to sign into their Intertwine account
	via their email and password credential combination.

	Keyword arguments:
	  cur - cursor to the database
	  email - user's email address
	  password - user's password

	Returns:
	  Python dictionary containing success status, error and
	  error codes, and optional payload.
	"""
	if not email:
		logging.error('no email provided for signing into email account')
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)
	if not password:
		logging.error('password is missing for %s %s (%s)', first, last, email)
		return intertwine.response.block(error=strings.VALUE_ERROR, code=500)

	# Attempt to look the user up in the database. They should exists
	# if they are trying to sign in with their email address.
	try:
		cur.execute("SELECT password, password_salt, id FROM accounts WHERE email=%s", (email,))
	except Exception as exc:
		logging.error('failed to query for user with email {0}\n{1}'.format(email, exc))
		# Our query raised an exception.
		return intertwine.response.block(error=strings.strings.VALUE_ERROR
strings.strings.VALUE_ERROR
strings.SERVER_ERROR, code=500)

	# With the results we get back (which is really only one row)
	# we will extract the hashed_password and check it with the 
	# attempted password.	
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
			# We can send back a good response now, the password
			# is correct.
			return intertwine.response.block()
		else:
			# Incorrect password
			logging.debug('%s\'s password rejected', email)	
	else:
		# Incorrect email
		logging.debug('%s is an invalid email address', email)

	# If the code has reached this point, it's an invalid login.
	# Code 401 (unauthorized).
	return intertwine.response.block(error=strings.INVALID_LOGIN, code=401)
	