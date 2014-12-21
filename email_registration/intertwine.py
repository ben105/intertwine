import json
import re
import psycopg2
from flask import Flask
from validate_email import validate_email

app = Flask(__name__)

char_limit = 20
pass_min_length = 8

def check_name(name):
	if len(name) > char_limit:
		return 'Please enter a name with less than {} characters'.format(char_limit)
	if not re.match("^[a-zA-Z-\.]*$", name):
		return 'Please use only letters for your name'
	return None

def check_password(password):
	if len(password) < pass_min_length:
		return 'Please enter a password with at least 8 characters'
	if not re.match("^[a-zA-Z0-9_\-#@]*$", password):
		return "Please only use letters and numbers, or '_', '-', '#', '@', '*'"
	return None 


@app.route('/')
def hello():
	return "Hello World!"

@app.route('/api/v1/adduser/first/<first>/last/<last>/email/<email>/password/<password>')
def email_register(first, last, email, password):

	errors = dict()
	err = check_name(first)
	if err:
		errors['first'] = err

	err = check_name(last)
	if err:
		errors['last'] = err

	err = check_password(password)
	if err:
		errors['password'] = err

	if not validate_email(email, check_mx=True):
		errors['email'] = 'Please enter a valid email address'

	try:	
		conn = psycopg2.connect("dbname=intertwine host=localhost user=brooke password=intertwine")
	except Exception as exc:
		print "Couldn't connect to postgres {}".format(exc)

	cur = conn.cursor()
	cur.connection.autocommit = True
	try:
		cur.execute("SELECT * FROM accounts WHERE email=%s", (email,))
		rows = cur.fetchall()
		if len(rows):
			errors['email'] = 'An account already exists'
	except Exception as exc:
		print "Couldn't run execution"

	
	if len(errors.keys()):
		return json.dumps(errors)		


	try:
		cur.execute("INSERT INTO accounts (email, u_id, first, last) VALUES (%s, %s, %s, %s);", (email, email, first, last))
	except Exception as exc:
		return json.dumps( { "psyco-error":str(exc) } )
	
	return json.dumps( {"success":"true"} )

if __name__ == "__main__":
	app.run(host='0.0.0.0')


