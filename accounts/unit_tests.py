import unittest
from intertwine import accounts

def garbage_string():
	return "daagd432$QE@"

class TestAccounts(unittest.TestCase):
	"""TestAccounts will provide the unit test framework for testing
	the accounts module.
	"""	

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
		pass

	def test_empty_salt_saltnhash(self):
		pass

	# The following are to test
	# create_email_account(email, first, last, password)
	
	def test_empty_email_create_email(self):
		pass

	def test_invalid_email_create_email(self):
		pass

	def test_bad_mx_create_email(self):
		pass

	def test_empty_first_create_email(self):
		pass

	def test_empty_last_create_email(self):
		pass	

	def test_empty_password_create_email(self):
		pass

if __name__ == "__main__":
	unittest.main()
