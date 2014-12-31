"""Registration Validation
This module abstracts the logic for validating
the fields in the email registration process.
"""
import validate_email
import psycopg2
import re

char_limit = 20
pass_min_length = 8

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
		conn = psycopg2.connect("dbname=intertwine host=localhost user=brooke password=intertwine")
	except Exception as exc:
		return "Couldn't connect to postgres {}".format(exc)
	cur = conn.cursor()
	cur.connection.autocommit = True
	try:
		cur.execute("SELECT * FROM accounts WHERE email=%s", (email,))
		rows = cur.fetchall()
		if len(rows):
			return 'An account already exists'
	except Exception as exc:
		return "Couldn't run execution"
	return None

def duplicate_facebook_id(facebook_id):
	try:	
		conn = psycopg2.connect("dbname=intertwine host=localhost user=brooke password=intertwine")
	except Exception as exc:
		return "Couldn't connect to postgres {}".format(exc)
	cur = conn.cursor()
	cur.connection.autocommit = True
	try:
		cur.execute("SELECT * FROM accounts WHERE facebook_id=%s", (facebook_id,))
		rows = cur.fetchall()
		if len(rows):
			return 'An account already exists'
	except Exception as exc:
		return "Couldn't run execution"
	return None
	
