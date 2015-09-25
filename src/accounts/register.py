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
from intertwine.accounts import accounts

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
k_err_min_chars = 'Cannot enter an empty string'
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



def invalid_name(name):
	"""Check the name fields. If the field has more than the
	character limit or uses incorrect characters, an error will
	be returned. Otherwise, None will be returned.

	Keyword arguments:
	name -- first or last name string

	Return value:
	Either an error string, or a None value.
	"""
	if not name:
		return k_err_min_chars
	if len(name.strip()) == 0:
		return k_err_min_chars
	if len(name) > char_limit:
		logging.warning('validation warning, "%s" name greater than character limit', name)
		return k_err_char_limit
	if not re.match("^[a-zA-Z-\.]*$", name):
		logging.warning('validation warning, "%s" invalid characters', name)
		return k_err_invalid_characters
	return None

def invalid_password(password):
	"""Check the value of the password. We will return an error 
	if the password is too short, or if there are invalid characters
	being used.

	Keyword Arguments:
	password -- the user's password

	Return value:
	Either an error string, or a None value.
	"""
	if not password:
		return k_err_min_chars
	if len(password) < pass_min_length:
		logging.warning('validation warning, password is less than minimum length (%d)', pass_min_length)
		return k_err_password_size
	if not re.match("^[a-zA-Z0-9_\-#@]*$", password):
		logging.warning('validation warning, invalid characters being used for password')
		return k_err_password_chars
	return None 


def invalid_email(email):
	"""Check that the email address is of a valid domain. We are
	not currently checking that the email address is registered.
	This should be updated at some point.

	Keyword arguments:
	email -- the user's email address

	Return value:
	Either an error string, or a None value.
	"""
	if not email:
		return k_err_min_chars
	if not validate_email.validate_email(email, check_mx=True):
		logging.warning('validation warning, failed to validate email %s', email)
		return k_err_invalid_email
	return None

def duplicate_email(ctx, email):
	"""Verify that the email address is not already 
	registered in the Intertwine database. 

	Keyword argument:
	email -- the user's email address

	Return value:
	Either an error string, or a None value.
	"""
	if not email:
		return k_err_min_chars
	try:
		logging.info("checking for duplicate account %s", email)
		ctx.cur.execute("SELECT * FROM accounts WHERE email=%s", (email,))
		rows = ctx.cur.fetchall()
		if len(rows):
			logging.info('validation warning, duplicate account found for email %s', email)
			return k_err_duplicate_account
	except Exception as exc:
		logging.error('validation exception raised validating email, %s', exc)
		return k_err_server_problem
	return None

def register(ctx, first, last, email, password, facebook_id, account_type):
	# Let' validate the content the user has entered
	errors = {}
	if account_type == "email":
		err = register.invalid_name(first)
		if err:
			errors['first'] = err
		err = register.invalid_name(last)
		if err:
			errors['last'] = err
		err = register.invalid_password(password)
		if err:
			errors['password'] = err
		err = register.invalid_email(email)
		if err:
			errors['email'] = err
		err = register.duplicate_email(cur, email)
		if err:
			errors['email'] = err
	# Now that we've done some validation, we can
	# send back the error dictionary if it has any
	# values.
	if len(errors.keys()):
		return response.block(error='One of the registration fields was invalid', payload=errors, code=INVALID_LOGIN)    
	# If we don't have any errors, then we can 
	# continue.
	# Create the account.
	if account_type == "email":
		return accounts.create_account_email(ctx, email=email, first=first, last=last, password=password)
	elif account_type == "facebook":
		return accounts.sign_in_facebook(ctx, facebook_id, first, last)
	return response.block(error="Incorrect account type.", code=SERVER_ERROR)


