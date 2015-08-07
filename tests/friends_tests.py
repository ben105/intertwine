import unittest
import psycopg2

import intertwine.testdb

import intertwine.friends.friend_requests

cur = None

def cursor(cursor):
	global cur
	cur = cursor



class TestFriendRequests(unittest.TestCase):

	def setUp(self):
		if cur is None:
			raise ValueError('database cursor must be set before running test case')

	def test_adding_friend(self):
		pass

	def test_removing_friend(self):
		pass

	def test_sending_request_valid(self):
		pass

	def test_sending_request_invalid_1(self):
		pass

	def test_sending_request_invalid_2(self):
		pass

	def test_accepting_requests(self):
		pass



if __name__ == '__main__':
	global cur
	cur = intertwine.testdb.start()

	unittest.main()

	cur.connection.close()
