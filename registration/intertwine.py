import json
import re
import psycopg2
from flask import Flask, request
import registration_validation as rv
import intertwine_account
import intertwine_psql

app = Flask(__name__)

cur = intertwine_psql.connect()
rv.set_database_cursor(cur)
intertwine_account.set_database_cursor(cur)

@app.route('/api/v1/signin', methods=['POST'])
def sign_in():
	email = request.form.get('email')
	password = request.form.get('password')
	# Check that we have retrieved valid stuff from the post form
	if not (email and password):
		return json.dumps({'error':'Invalid login credentials.'})
	# Attempt to sign in. Make a connection to the database
	if intertwine_account.sign_in(email, password):
		return json.dumps({'success':'true'})
	else:
		return json.dumps({'error':'Invalid login credentials.'})	

@app.route('/api/v1/adduser', methods=['POST'])
def add_user():
	# Errors dict to store all errors
	errors = dict()
	# Extract the POST data
	first = request.form.get('first')
	last = request.form.get('last')
	email = request.form.get('email')
	facebook_id = request.form.get('facebook_id')
	password = request.form.get('password')
	account_type = request.form.get('account_type')
	# Let' validate the content the user has entered
	err = rv.invalid_name(first)
	if err:
		errors['first'] = err
	err = rv.invalid_name(last)
	if err:
		errors['last'] = err
	err = rv.invalid_password(password)
	if err:
		errors['password'] = err
	err = rv.invalid_email(email)
	if err:
		errors['email'] = err
	# Make a connection to the postgres database
	try:
		conn = psycopg2.connect("dbname=intertwine host=localhost user=brooke password=intertwine")
		cur = conn.cursor()
		cur.connection.autocommit = True
	except:
		errors['connection'] = 'Connection issues on the server'
		return errors
	# Check if there is already an account with this email
	if account_type == "email":
		err = rv.duplicate_email(email)
		if err:
			errors['email'] = err
	# Now that we've done some validation, we can
	# send back the error dictionary if it has any
	# values.
	if len(errors.keys()):
		return json.dumps(errors)	
	# If we don't have any errors, then we can 
	# continue.
	# Create the account.
	if account_type == "email":
		err = intertwine_account.create_account_email(email=email, first=first, last=last, password=password)
		if err:
			errors['connection'] = err
			return errors
	elif account_type == "facebook":
		intertwine_account.create_account_facebook()
	else:
		print "Need to log an incorrect account type!" # TODO
		return json.dumps( {"error":"Incorrect account type."} )
	# Succesfully created an account
	#cur.connection.close()
	return json.dumps( {"success":"true"} )


@app.route('/api/v1/friendrequest', methods=['POST', 'GET'])
def friend_request():
	"""Friend request can either be a get
	or a post. A get will simply return
	the results of all pending friend 
	requests, while a post will initiate
	a friend request.
	"""
	if request.method == "GET":
		user_id = request.form.get('user_id')
		users_requests = friend_requests.get_requests(user_id)
	elif request.method == "POST":
		requester_id = request.form.get('requester_id')
		requestee_id = request.form.get('requestee_id')

if __name__ == "__main__":
	app.run(host='0.0.0.0')


