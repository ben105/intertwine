import unittest
import intertwine
import util
import intertwine.response as response
import intertwine.strings as strings
import time

import intertwine.accounts.intertwine_account as accounts
import intertwine.accounts.register as register
import intertwine.accounts.search as search


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
		resp = accounts.create_email_account(
				cur, email='', first='Ben', last='Rooke', password='password1')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_empty_first_create_email(self):
		resp = accounts.create_email_account(
				cur, email='ben_rooke@icloud.com', first='', last='Rooke', password='password1')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_empty_last_create_email(self):
		resp = accounts.create_email_account(
				cur, email='ben_rooke@icloud.com', first='Ben', last='', password='password1')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_empty_password_create_email(self):
		resp = accounts.create_email_account(
				cur, email='ben_rooke@icloud.com', first='Ben', last='Rooke', password='')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_duplicate_email_account(self):
		accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		cur.connection.commit()
		cur.execute('SELECT * FROM accounts WHERE email=%s', ('ben_rooke@icloud.com',))
		rows = cur.fetchall()
		self.assertEqual(len(rows), 1)
		resp = accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.SERVER_ERROR)

	# The following are to test the Facebook login.

	def test_valid_facebook_login(self):
		facebook_id = '1301290360'
		first = 'Ben'
		last = 'Rooke'
		resp = accounts.sign_in_facebook(cur, facebook_id, first, last)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])

	def test_empty_facebook_login_fb_id(self):
		first = 'Ben'
		last = 'Rooke'
		resp = accounts.sign_in_facebook(cur, '', first, last)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		# self.assertEqual(resp['error'], <some error string>)

	def test_empty_facebook_login(self):
		facebook_id = '1301290360'
		first = 'Ben'		
		last = 'Rooke'
		# Empty first name.
		resp = accounts.sign_in_facebook(cur, facebook_id, '', last)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		#self.assertEqual(resp['error'], <some error string> )
		# Empty last name.
		resp = accounts.sign_in_facebook(cur, facebook_id, first, '')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_relogin_fb_account(self):
		facebook_id = '1301290360'
		first = 'Ben'		
		last = 'Rooke'
		for i in range(5):
			resp = accounts.sign_in_facebook(cur, facebook_id, first, last)
			self.assertTrue(resp['success'])
			self.assertIsNone(resp['error'])
			time.sleep(1)

	def test_relogin_after_deleting_fb_account(self):
		facebook_id = '1301290360'
		first = 'Ben'		
		last = 'Rooke'
		for i in range(5):
			resp = accounts.sign_in_facebook(cur, facebook_id, first, last)
			self.assertTrue(resp['success'])
			self.assertIsNone(resp['error'])
			cur.execute('DELETE FROM accounts WHERE facebook_id = %s', (facebook_id,)) #Facebook ID is unique
			cur.connection.commit()
			time.sleep(1)

	# Test the sign in email feature.

	def test_sign_in_email(self):
		accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		resp = accounts.sign_in_email(cur, 'ben_rooke@icloud.com', 'password1')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])

	def test_sign_in_multiple_times(self):
		accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		for i in range(5):
			resp = accounts.sign_in_email(cur, 'ben_rooke@icloud.com', 'password1')
			self.assertTrue(resp['success'])
			self.assertIsNone(resp['error'])
		cur.execute('DELETE FROM accounts WHERE email = %s;', ('ben_rooke@icloud.com',))
		cur.connection.commit()
		resp = accounts.sign_in_email(cur, 'ben_rooke@icloud.com', 'password1')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.INVALID_LOGIN)

	def test_sign_in_invalid_credentials(self):
		accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		resp = accounts.sign_in_email(cur, 'ben@icloud.com', 'Ben', 'Rooke', 'password1')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.INVALID_LOGIN)
		resp = accounts.sign_in_email(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'incorrect_password')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.INVALID_LOGIN)

	def test_sign_in_missing_email(self):
		resp = accounts.sign_in_email(cur,'', 'password')
		self.assertFalse(resp['success'])
		self.assertIsNotNone(resp['error'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = accounts.sign_in_email(cur, 'ben_rooke@icloud.com', '')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)


	#
	# Time to test the registration procedures!
	# Make sure it's not possible to violate some 
	# of the registration restrictions, and also
	# make sure you can successfully register!
	#
	# invalid_name(name):
	# invalid_password(password):
	# invalid_email(email):
	# duplicate_email(email):

	def test_register_invalid_name(self):
		resp = register.invalid_name('')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_name('   ')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_name('Ben Rooke')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_name('Ben')
		self.assertEqual(resp['success'])
		self.assertIsNone(resp['error'])


	def test_register_invalid_password(self):
		resp = register.invalid_password('')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_password('minlen') # minimum length
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_password('^^^^^^^^^^^')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_password('valid_password')
		self.assertEqual(resp['success'])
		self.assertIsNone(resp['error'])

	def test_register_invalid_email(self):
		resp = register.invalid_email('')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_email('ben_rooke') # no @domain
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_email('this123_email123_does123_not123_exist123@icloud.com')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = register.invalid_email('ben_rooke@icloud.com')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])

	def test_register_duplicate_email(self):
		accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke')
		isDupe = register.duplicate_email('observer105@gmail.com') # Not in the database
		self.assertFalse(isDupe)
		isDupe = register.duplicate_email('ben_rooke@icloud.com')
		self.assertTrue(isDupe)


	# Test the search (find) API
	# Additionaly, test the following things:
	# - we don't see blocked users
	# - we see more relevant people at the top

	def test_find_with_success(self):
		resp = accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke')
		user_id = resp['payload']['user_id']
		accounts.create_email_account(cur, 'amulcahy@scu.edu', 'Alex', 'Mulcahy')
		accounts.sign_in_facebook(cur, '1301290360', 'Alex', 'Jaczak')
		
		results = search.find(cur, user_id, 'Alex')
		self.assertEqual(len(results), 2)
		names = [result['first'] for result in results]
		self.assertTrue(all(map(lambda x: x == 'Alex', names)))
		
		results = search.find(cur, user_id, 'alex')
		self.assertEqual(len(results), 2)
		names = [result['first'] for result in results]
		self.assertTrue(all(map(lambda x: x == 'Alex', names)))

		results = search.find(cur, user_id, 'alex mulcahy')
		self.assertEqual(len(results), 1)
		result = results[0]
		name = "{} {}".format(result['first'], result['last'])
		self.assertEqual(name, 'Alex Mulcahy')

		results = search.find(cur, user_id, 'Bobby')
		self.assertEqual(len(results), 0)
		

if __name__ == '__main__':
	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()