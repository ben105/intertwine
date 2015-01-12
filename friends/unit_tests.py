import unittest
import psycopg2
from friend_requests import *

class TestFriendRequests(unittest.TestCase):

	def setUp(self):
		conn = psycopg2.connect("dbname=intertwine")
		self.cur = conn.cursor()
		self.cur.connection.autocommit = True

	def tearDown(self):
		self.cur.connection.close()

	def test_adding_friend(self):
		

	def test_removing_friend(self):

	def test_sending_request_valid(self):
	def test_sending_request_invalid_1(self):
	def test_sending_request_invalid_2(self):

	def test_accepting_requests(self):

