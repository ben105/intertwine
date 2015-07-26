import unittest
import intertwine.testdb

import intertwine.accounts.intertwine_account as accounts

cur = None

def cursor(cursor):
	global cur
	cur = cursor

def garbage_string():
	return "daagd432$QE@"

class TestAccounts(unittest.TestCase):
	"""TestAccounts will provide the unit test framework for testing
	the accounts module.
	"""	

	def tearDown(self):
		cur.execute("DELETE FROM accounts;")

	# The following tests are for
	# random_salt(salt_len)

	def test_negative_length_salt(self):
		with self.assertRaises(ValueError):
			accounts.random_salt(-1)

	def test_zero_length_salt(self):
		with self.assertRaises(ValueError):
			accounts.random_salt(0)

	def test_positive_length_salt(self):
		salt = accounts.random_salt(16)
		self.assertTrue( len(salt) > 0 )

	def test_randomness(self):
		salt1 = accounts.random_salt(16)
		salt2 = accounts.random_salt(16)
		self.assertFalse( salt1 == salt2 )

	# The following are tests for
	# salt_and_hash(password, salt)

	def test_empty_password_saltnhash(self):
		with self.assertRaises(ValueError):
			accounts.salt_and_hash('', 'somesalt')

	def test_empty_salt_saltnhash(self):
		with self.assertRaises(ValueError):
			accounts.salt_and_hash('somepassword', '')

	# The following are to test
	# create_email_account(email, first, last, password)
	
	def test_empty_email_create_email(self):
		with self.assertRaises(ValueError):
			accounts.create_email_account(
				cur, email='', first='Ben', last='Rooke', password='password1')

	def test_empty_first_create_email(self):
		with self.assertRaises(ValueError):
			accounts.create_email_account(
				cur, email='ben_rooke@icloud.com', first='', last='Rooke', password='password1')

	def test_empty_last_create_email(self):
		with self.assertRaises(ValueError):
			accounts.create_email_account(
				cur, email='ben_rooke@icloud.com', first='Ben', last='', password='password1')

	def test_empty_password_create_email(self):
		with self.assertRaises(ValueError):
			accounts.create_email_account(
				cur, email='ben_rooke@icloud.com', first='Ben', last='Rooke', password='')

	def test_duplicate_email_account(self):
		accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		with self.assertRaises(Exception):
			accounts.create_email_account(
				cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')


if __name__ == '__main__':
	global cur
	cur = intertwine.testdb.start()

	unittest.main()

	cur.connection.close()

