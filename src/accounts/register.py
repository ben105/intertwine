"""Registration Validation
This module abstracts the logic for validating
the fields in the email registration process.
"""
import validate_email
import psycopg2
import re
import logging

from intertwine import response
from intertwine import strings

# Global varibale declarations
# 
# Includes:
# - character limits on name fields
# - minimum length of password (for security)
# - the database cur, with open connection
# - various error messages in response to requests
char_limit = 20
pass_min_length = 8
db_cur = None
#
# Server Error
k_err_server_problem = 'There was a problem with the server validating your request'
#
# First and Last Name Errors
k_err_char_limit = 'Please enter a name with less than {} characters'.format(char_limit)
k_err_invalid_characters = 'Use only letters for your name'
#
# Password Errors
k_err_password_size = 'Please enter a password with at least 8 characters'
k_err_password_chars = "Please only use letters and numbers, or '_', '-', '#', '@', '*'"
#
# Email Errors
k_err_invalid_email = 'Please enter a valid email address'
#
# Duplicate Account
k_err_duplicate_account = 'An account already exists'


def check_none(func):
	"""This decorator function will check that the first parameter
	of a function is not None value. For the case of the functions
	used in this module, the first parameters are supposed to be
	retrieved from HTML form fields. If the fields were not present,
	or the request body was built improperly, then certain values
	may be None instead.
	In this case, we will return a server error message in our response.
	"""
	def inner(*argv, **kwarg):
		if len(argv) > 0:
			param1 = argv[0]
			if param1 == None:
				logging.warning('validationg warning, None type is invalid type', k_err_server_problem)
				return k_err_server_problem
		return func(*argv, **kwarg)
	return inner


def set_database_cur(cur):
	"""This is a convenience method to point the global variable
	to the passed in cur reference. This way we don't create
	a new database connection.

	Keyword arguments:
	  cursor -- cursor to the database
	"""
	global db_cur
	db_cur = cur

@check_none
def invalid_name(name):
	"""Check the name fields. If the field has more than the
	character limit or uses incorrect characters, an error will
	be returned. Otherwise, None will be returned.

	Keyword arguments:
	name -- first or last name string

	Return value:
	Either an error string, or a None value.
	"""
	if len(name) > char_limit:
		logging.warning('validation warning, "%s" name greater than character limit', name)
		return k_err_char_limit
	if not re.match("^[a-zA-Z-\.]*$", name):
		logging.warning('validation warning, "%s" invalid characters', name)
		return k_err_invalid_characters
	return None

@check_none
def invalid_password(password):
	"""Check the value of the password. We will return an error 
	if the password is too short, or if there are invalid characters
	being used.

	Keyword Arguments:
	password -- the user's password

	Return value:
	Either an error string, or a None value.
	"""
	if len(password) < pass_min_length:
		logging.warning('validation warning, password is less than minimum length (%d)', pass_min_length)
		return k_err_password_size
	if not re.match("^[a-zA-Z0-9_\-#@]*$", password):
		logging.warning('validation warning, invalid characters being used for password')
		return k_err_password_chars
	return None 

@check_none
def invalid_email(email):
	"""Check that the email address is of a valid domain. We are
	not currently checking that the email address is registered.
	This should be updated at some point.

	Keyword arguments:
	email -- the user's email address

	Return value:
	Either an error string, or a None value.
	"""
	if not validate_email.validate_email(email, check_mx=True):
		logging.warning('validation warning, failed to validate email %s', email)
		return k_err_invalid_email
	return None

@check_none
def duplicate_email(email):
	"""Verify that the email address is not already 
	registered in the Intertwine database. 

	Keyword argument:
	email -- the user's email address

	Return value:
	Either an error string, or a None value.
	"""
	try:
		logging.info("checking for duplicate account %s", email)
		db_cur.execute("SELECT * FROM accounts WHERE email=%s", (email,))
		rows = db_cur.fetchall()
		if len(rows):
			logging.info('validation warning, duplicate account found for email %s', email)
			return k_err_duplicate_account
	except Exception as exc:
		logging.error('validation exception raised validating email, %s', exc)
		return str(exc)
	return None
