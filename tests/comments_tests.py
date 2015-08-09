import psycopg2
from intertwine import push
from intertwine import strings
from intertwine.activity import comments
from intertwine.activity import events
from intertwine.friends import friends

class TestComments(unittest.TestCase):

	def setUp(self):
		if cur is None:
			raise ValueError('database cursor must be set before running test case')
		resp = accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		self.user_id = resp['payload']['user_id']

		facebook_friends = {'Ben Rooke':'123', 'Rae Jonathans':'456', 'Ashley Sellers':'789'}
		self.friend_ids = []
		for k, v in facebook_friends.iteritems():
			name_components = k.split()
			first = name_components[0]; last = name_components[1]
			resp = accounts.sign_in_facebook(cur, v, first, last)
			friend_id = resp['payload']['user_id']
			self.friend_ids.append(friend_id)

	def tearDown(self):
		cur.execute('DELETE FROM accounts;')
		cur.execute('DELETE FROM friends;')
		cur.execute('DELETE FROM friend_requests;')
		cur.execute('DELETE FROM comments;')
		cur.execute('DELETE FROM events;')

	#def comment_count(cur, event_id):
	def test_comment_count_none_event_id(self):
		count = comments.comment_count(cur, None)
		self.assertEqual(count, 0)
	
	def test_comment_count_no_comments(self):
		resp = friends.send_request(cur, self.user_id, )
	
	def test_comment_count_with_comments(self):
		pass
	
	def test_comment_count_after_adding_comments(self):
		pass

	def test_comment_count_event_does_not_exist(self):
		# Expect a NOT FOUND
		resp = comments.comment_count(cur, 2)

	
	
	#def get_comments(cur, event_id):
	def test_get_comments_none_event(self):
		pass

	def test_get_comments_no_comments(self):
		# Test payload is empty list
		pass

	def test_get_comments_with_comments(self):
		# Inspect each comment
		pass

	def test_get_comments_event_does_not_exist(self):
		pass

	
	def notify_attendees(cur, user_id, event_id, title, comment):
	def test_notify_bad_user_id(self):
		pass

	def test_notify_bad_event_id(self):
		pass

	def test_notify_bad_title(self):
		pass

	def test_notify_

	
	def add_comment(cur, user_id, event_id, comment):

if __name__ == '__main__':
	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()