import psycopg2
import time
import datetime
import hashlib
import random

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
	hashed_password = get_hash_password(password, salt)
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
	cur.execute(query, (email, first, last, password, password_salt, created_date))
	

def create_account_facebook(facebook_id, first, last, password):
	salt = random_salt(16)
	hashed_password = get_hash_password(password, salt)
	


def create_account():
