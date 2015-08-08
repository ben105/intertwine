import unittest
import psycopg2

import intertwine.testdb

from intertwine.friends import friends
from intertwine.accounts import accounts

from intertwine import strings

cur = None

def cursor(cursor):
	global cur
	cur = cursor

def insert_friends(cur, requestee, requester):
	insert_query = """
	INSERT INTO friends
		(accounts_id, friend_accounts_id)
	VALUES
		(%s, %s);
	"""
	cur.execute(insert_query, (requestee, requester)) #Requestee first
	cur.execute(insert_query, (requester, requestee)) #Requester first


# IMPORTANT:
# Things to think about when testing the friends.py module functions.
# - Are the friends blocked?
# - Is there a pending request?
# - Has the potential friend denied a request already?

class TestFriendRequests(unittest.TestCase):

	def setUp(self):
		if cur is None:
			raise ValueError('database cursor must be set before running test case')
		resp = accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		self.user_id = resp['payload']['user_id']

		facebook_friends = {'Ben Rooke':'123', 'Rae Jonathans':'456', 'Ashley Sellers':'789'}
		for k, v in facebook_friends.iteritems():
			name_components = k.split()
			first = name_components[0]; last = name_components[1]
			accounts.sign_in_facebook(cur, v, first, last)

	def tearDown(self):
		cur.execute('DELETE FROM accounts;')
		cur.execute('DELETE FROM friends;')
		cur.execute('DELETE FROM friend_requests;')
		cur.execute('DELETE FROM blocked_accounts;')
	
	# Testing the retrieval of people on Intertwine
	# who are your Facebook friends.
	# Parameters: cur, user_id, fb_list
	def test_fb_friends_bad_user_id(self):
		resp = friends.fb_friends(cur, None, ['123', '456', '789'])
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		self.assertEqual(len(resp['payload']), 0)

	def test_fb_friends_with_invalid_fb_list(self):
		resp = friends.fb_friends(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		self.assertEqual(len(resp['payload']), 0)

	def test_fb_friends_with_single_item_list(self):
		resp = friends.fb_friends(cur, self.user_id, ['123'])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(len(resp['payload']), 1)

	def test_fb_friends_with_none_intertwine_users(self):
		resp = friends.fb_friends(cur, self.user_id, ['123', '456', '555', '666', '777', '888'])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(len(resp['payload']), 2)

	def test_fb_friends_with_abnormal_large_list(self):
		fb_list = []
		for i in xrange(10000):
			fb_list.append(str(i))
		self.assertTrue(len(fb_list) == 10000)
		resp = friends.fb_friends(cur, self.user_id, fb_list)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(len(resp['payload']), 3)
	
	def test_fb_friends_with_one_who_has_blocked(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		blocker_id = cur.fetchone()[0]
		resp = friends.block_user(cur, self.user_id, blocker_id)
		self.assertTrue(resp['success'])
		resp = friends.fb_friends(cur, self.user_id, ['456'])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(len(resp['payload']), 0)

	def test_fb_friends_with_one_who_is_pending(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		requestee_id = cur.fetchone()[0]
		resp = friends.send_request(cur, self.user_id, requestee_id)
		self.assertTrue(resp['success'])
		resp = friends.fb_friends(cur, self.user_id, ['456'])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(len(resp['payload']), 0)

	def test_fb_friends_with_one_who_has_denied(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		requestee_id = cur.fetchone()[0]
		resp = friends.send_request(cur, self.user_id, requestee_id)
		self.assertTrue(resp['success'])
		resp = friends.deny(cur, requestee_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.fb_friends(cur, self.user_id, ['456'])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(len(resp['payload']), 0)


	# The next set of features is for testing the block
	# functionality. Let's make sure we can appropriately
	# block users.
	# Parameters: cur, user_id, block_user_id
	#
	# Once we've blocked a user, they should not be able
	# to show up on a search, or be a friend on the friends
	# list. 
	def test_blocking_a_friend(self):
		# Are they removed from the friends list?
		# Do a query to check...
		cur.execute('SELECT id FROM accounts WHERE facebook_id IS NOT NULL;')
		rows = cur.fetchall()
		friends_to_block = [_id for row[0] in rows]
		for friend in friends_to_block:
			# Add them as a friend first.
			resp = friends.send_request(cur, self.user_id, friend)
			self.assertTrue(resp['success'])
			
			# Accept the friend requests.
			resp = friends.accept_request(cur, friend, self.user_id)
			self.assertTrue(resp['success'])

		# Confirm positive friend count.
		resp = friends.get_friends(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertEqual(len(friends_to_block), len(resp['payload']))

		for friend in friends_to_block:
			# Block the friend.
			resp = friends.block(cur, self.user_id, friend)
			self.assertTrue(resp['success'])

		# Confirm no friends now.
		resp = friends.get_friends(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertEqual(0, len(resp['payload']))

	def test_blocking_with_bad_user_id(self):
		resp = friends.block(cur, None, '123')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_blocking_with_bad_block_id(self):
		resp = friends.block(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_blocking_where_block_id_does_not_exist(self):
		resp = friends.block(cur, self.user_id, '2764389')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_blocking_with_already_blocked(self):
		# We expect this to just fail gracefully
		# (i.e.) nothing happens.
		resp = friends.block(cur, self.user_id, '123')
		resp = friends.block(cur, self.user_id, '123')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])


	# Getting a list of people you have already blocked.
	#def get_blocked(cursor, user_id):
	def test_getting_blocked_bad_user_id(self):
		resp = friends.get_blocked(cur, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_getting_blocked_none_blocked(self):
		resp = friends.get_blocked(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(0, len(resp['payload']))

	def test_getting_blocked(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.block(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM blocked_accounts WHERE accounts_id=%s and blocked_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)

	# Testing the release of a block
	#def purge_blocked(cursor, user_id, blocked_user_id):
	def test_purge_block_bad_user_id(self):
		resp = friends.purge_blocked(cur, None, self.user_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_purge_block_bad_block_id(self):
		resp = friends.purge_blocked(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_purge_block_not_actually_blocked(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.purge_blocked(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_purge_block_success(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.block(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM blocked_accounts WHERE accounts_id=%s and blocked_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)
		resp = friends.purge_blocked(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM blocked_accounts WHERE accounts_id=%s and blocked_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)

	def test_purge_block_multiple_blocked(self):
		# Make sure purging one account doesn't
		# affect any other accounts.
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('789',))
		person2_id = cur.fetchone()[0]
		resp = friends.block(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.block(cur, self.user_id, person2_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM blocked_accounts WHERE accounts_id=%s and blocked_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 2)
		resp = friends.purge_blocked(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM blocked_accounts WHERE accounts_id=%s and blocked_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)
	

	# Pending requests
	# Make sure we don't show people who are blocked.
	#def get_pending_requests(cursor, user_id):
	def test_pending_requests_bad_user_id(self):
		resp = friends.get_pending_requests(cur, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_pending_requests_no_requests(self):
		resp = friends.get_pending_requests(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friend_requests WHERE requestee_accounts_id=%s;', (self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)

	def test_pending_requests(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.get_pending_requests(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friend_requests WHERE requestee_accounts_id=%s;', (self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)
	
	# The list of friends you have, who are not blocked.
	#def get_friends(cursor, user_id):
	def test_get_friends_bad_user_id(self):
		resp = friends.get_friends(cur, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_get_friends_no_friends(self):
		resp = friends.get_friends(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s;', (self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)

	def test_get_friends_after_accepting_request(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.get_friends(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s;', (self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)

	def test_get_friends_after_blocking(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.block(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.get_friends(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s;', (self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)

	def test_remove_friend_then_add_friend(self):
		# Should look the same in the end.
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.remove_friend(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.get_friends(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s;', (self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)

	# Declining a friend request.
	# We should check if the person is still on the list.
	#def decline_request(cur, requestee, requester):

	def test_decline_bad_requestee(self):
		resp = friends.decline_request(cur, None, self.user_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_decline_bad_requester(self):
		resp = friends.decline_request(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_decline_not_a_real_request(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_decline_of_request(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.decline_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friend_requests WHERE requestee_accounts_id=%s and requester_accounts_id=%s;', (person_id, self.user_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s and friend_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)

	# Removing a friend.
	# Can't remove a friend that doesn't exist.
	#def remove_friend(cur, user_id, friend_user_id):

	def test_remove_friend_bad_user_id(self):
		resp = friends.remove_friend(cur, None, self.user_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_remove_friend_bad_friend_id(self):
		resp = friends.remove_friend(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_remove_friend_does_not_exist(self):
		resp = friends.remove_friend(cur, self.user_id, '5555555')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_remove_friend_not_a_friend(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.remove_friend(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_remove_friend(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s and friend_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)
		resp = friends.remove_friend(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friends WHERE accounts_id=%s and friend_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)

	# Sending a friend request.
	# Make sure it shows up in the pending list of the alternative user.
	#def send_request(cursor, requester, requestee):
	def test_send_request_bad_requester(self):
		resp = friends.send_request(cur, None, self.user_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_send_request_bad_requestee(self):
		resp = friends.send_request(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_send_request_same_id(self):
		resp = friends.send_request(cur, self.user_id, self.user_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_send_request_does_not_exist(self):
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_send_request_already_sent(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_send_request_blocked_requestee(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.block(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_send_request_already_denied(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.deny(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_send_request(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friend_request WHERE requester_accounts_id=%s and requestee_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 1)


	# Accept request.
	# It should be removed from pending requests.
	# Both people should be in the friends list now.
	#def accept_request(cursor, requestee, requester):
	def test_accept_bad_requestee(self):
		resp = friends.accept_request(cur, None, '123')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_accept_bad_requester(self):
		resp = friends.accept_request(cur, self.user_id, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_accept_nonexistent_requestee(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.accept_request(cur, self.user_id, '555')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_accept_nonexistent_requester(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.accept_request(cur, None, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_accept_already_accepted(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertFalse(resp['success'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_accept(self):
		cur.execute('SELECT id FROM accounts WHERE facebook_id = %s;', ('456',))
		person_id = cur.fetchone()[0]
		resp = friends.send_request(cur, person_id, self.user_id)
		self.assertTrue(resp['success'])
		resp = friends.accept_request(cur, self.user_id, person_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		cur.execute('SELECT count(*) FROM friend_request WHERE requester_accounts_id=%s and requestee_accounts_id=%s;', (self.user_id, person_id))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(count, 0)



if __name__ == '__main__':
	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()
