"""Registration Validation
This module abstracts the logic for validating
the fields in the email registration process.
"""
import validate_email
import psycopg2
import re

char_limit = 20
pass_min_length = 8
db_cursor = None

def set_database_cursor(cursor):
	global db_cursor
	db_cursor = cursor

def invalid_name(name):
	if len(name) > char_limit:
		return 'Please enter a name with less than {} characters'.format(char_limit)
	if not re.match("^[a-zA-Z-\.]*$", name):
		return 'Please use only letters for your name'
	return None

def invalid_password(password):
	if len(password) < pass_min_length:
		return 'Please enter a password with at least 8 characters'
	if not re.match("^[a-zA-Z0-9_\-#@]*$", password):
		return "Please only use letters and numbers, or '_', '-', '#', '@', '*'"
	return None 

def invalid_email(email):
	if not validate_email.validate_email(email, check_mx=True):
		return 'Please enter a valid email address'
	return None

def duplicate_email(email):
	try:
		db_cursor.execute("SELECT * FROM accounts WHERE email=%s", (email,))
		rows = db_cursor.fetchall()
		if len(rows):
			return 'An account already exists'
	except Exception as exc:
		return str(exc)
	return None

def duplicate_facebook_id(facebook_id):
	try:
		db_cursor.execute("SELECT * FROM accounts WHERE facebook_id=%s", (facebook_id,))
		rows = db_cursor.fetchall()
		if len(rows):
			return 'An account already exists'
	except Exception as exc:
		return str(exc)
	return None
	
