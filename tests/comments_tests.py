import unittest
import psycopg2

import intertwine.testdb

from intertwine import push
from intertwine import strings
from intertwine.activity import comments
from intertwine.activity import events
from intertwine.friends import friends
from intertwine.accounts import accounts

cur = None

class FalseRequest(object):
	def __init__(self, user_id=None, first='', last=''):
		self.headers = { 'user_id':user_id, 'first':first, 'last':last }

def FalseSecurityContext(cur, user_id=None, first='', last=''):
	request = FalseRequest(user_id, first, last)
	return context.SecurityContext(request, cur)

class TestComments(unittest.TestCase):

	def setUp(self):
		self.ctx = FalseSecurityContext(cur)
		resp = accounts.create_email_account(self.ctx, email='ben_rooke@icloud.com', first='Ben', last='Rooke', password='password1')
		self.ctx.user_id = resp['payload']['user_id']
		

		facebook_friends = {'Rae Jonathans':'456', 'Ben Rooke':'123', 'Ashley Sellers':'789'}
		self.friend_ids = []
		for k, v in facebook_friends.iteritems():
			name_components = k.split()
			first = name_components[0]; last = name_components[1]
			resp = accounts.sign_in_facebook(self.ctx, v, first, last)
			friend_id = resp['payload']['user_id']
			self.friend_ids.append(friend_id)

	def tearDown(self):
		cur.execute('DELETE FROM accounts;')
		cur.execute('DELETE FROM friends;')
		cur.execute('DELETE FROM friend_requests;')
		cur.execute('DELETE FROM comments;')
		cur.execute('DELETE FROM events;')

	#def comment_count(self.ctx, event_id):
	def test_comment_count_none_event_id(self):
		count = comments.comment_count(self.ctx, None)
		self.assertEqual(count, 0)
	
	def test_comment_count_no_comments(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx, ctx.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		count = comments.comment_count(self.ctx, event_id)
		self.assertEqual(count, 0)
	
	def test_comment_count_with_comments(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']

		# Make some comments!
		resp = comments.comment(self.ctx, friend_id, 'Rae', 'Jonathans', event_id, 'Coffee before work', 'You trying to leave before 7:00?')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		count = comments.comment_count(self.ctx, event_id)
		self.assertEqual(count, 1)
		cur.execute('SELECT count(*) FROM comments WHERE events_id=%s;', (event_id,))
		count = cur.fetchone()[0]
		self.assertEqual(count, 1)
	
		# Add another comment and check count again.
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Yeah. Is that cool?')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		count = comments.comment_count(self.ctx, event_id)
		self.assertEqual(count, 2)
		cur.execute('SELECT count(*) FROM comments WHERE events_id=%s;', (event_id,))
		count = cur.fetchone()[0]
		self.assertEqual(count, 2)

	def test_comment_count_event_does_not_exist(self):
		resp = comments.comment_count(self.ctx, 2)
		self.assertEqual(count, 0)
	
	
	#def get_comments(self.ctx, event_id):
	def test_get_comments_none_event(self):
		resp = comments.get_comments(self.ctx, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_get_comments_no_comments(self):
		# Test payload is empty list
		friend_id = self.friend_ids[0]
		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']

		resp = comments.get_comments(self.ctx, event_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(0, len(resp['payload']))

	def test_get_comments_with_comments(self):
		# Inspect each comment
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']

		# Make a comment.
		resp = comments.comment(self.ctx, friend_id, 'Rae', 'Jonathans', event_id, 'Coffee before work', 'You trying to leave before 7:00?')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])

		resp = comments.get_comments(self.ctx, event_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		posted_comments = resp['payload']

		# We need some additional information about the friend who
		# posted this comment, so we should look this up first.
		cur.execute('SELECT first, last, email, facebook_id FROM accounts WHERE id=%s;', (friend_id,))
		row = cur.fetchone()
		first = row[0]
		last = row[1]
		email = row[2]
		facebook_id = row[3]

		posted_comment = posted_comments[0]
		self.assertEqual(posted_comment['user']['id'], friend_id)
		self.assertEqual(posted_comment['user']['first'], first)
		self.assertEqual(posted_comment['user']['last'], last)
		self.assertEqual(posted_comment['user']['email'], email)
		self.assertEqual(posted_comment['user']['facebook_id'], facebook_id)
		self.assertEqual(posted_comment['comment'], 'You trying to leave before 7:00?')

		# Make another comment, and check when there is a list > 1.
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Heck no!')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])

		resp = comments.get_comments(self.ctx, event_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		posted_comments = resp['payload']
		self.assertEqual(len(posted_comments), 2)
		# The comments should be sent back from least to most recent.
		first_comment = posted_comments[0]
		second_comment = posted_comments[1]
		self.assertEqual(first_comment['user']['id'], friend_id)
		self.assertEqual(first_comment['user']['first'], first)
		self.assertEqual(first_comment['user']['last'], last)
		self.assertEqual(first_comment['user']['email'], email)
		self.assertEqual(first_comment['user']['facebook_id'], facebook_id)
		self.assertEqual(first_comment['comment'], 'You trying to leave before 7:00?')
		self.assertEqual(second_comment['user']['id'], self.user_id)
		self.assertEqual(second_comment['user']['first'], 'Ben')
		self.assertEqual(second_comment['user']['last'], 'Rooke')
		self.assertEqual(second_comment['user']['email'], 'ben_rooke@icloud.com')
		self.assertEqual(second_comment['user']['facebook_id'], None)
		self.assertEqual(second_comment['comment'], 'Heck no!')

	def test_get_comments_event_does_not_exist(self):
		# Expect NOT FOUND.
		resp = comments.get_comments(self.ctx, 333666999)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	
	# Notify attendees!
	#def notify_attendees(self.ctx, user_id, event_id, title, comment):
	def test_notify_no_event_exists(self):
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', 555, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)

	def test_notify_no_attendees(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		# Remove the attendess (a freak accident!)
		cur.execute('DELETE FROM event_attendees;')
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)

	def test_notify_success(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertTrue(succ)

	def test_notify_bad_user_id(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		# We are just going to call this function with a bad
		# user_id, and it should just fail gracefully (i.e. not raise an exception).
		succ = comments.notify_attendees(self.ctx, None, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)
		succ = comments.notify_attendees(self.ctx, None, 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)
		succ = comments.notify_attendees(self.ctx, 'Ben', None, event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)
		succ = comments.notify_attendees(self.ctx, None, '', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)
		succ = comments.notify_attendees(self.ctx, '', None, event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)

	def test_notify_bad_event_id(self):
		succ = comments.notify_attendees(self.ctx, None, 'Ben', 'Rooke', 'Coffee before work', 'Hello, world!')
		self.assertFalse(succ)

	def test_notify_bad_title(self):
		# Test empty string as well as None.
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', event_id, '', 'Hello, world!')
		self.assertFalse(succ)
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', event_id, None, 'Hello, world!')
		self.assertFalse(succ)

	def test_notify_bad_comment(self):
		# Test empty string as well as None.
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', None)
		self.assertFalse(succ)
		succ = comments.notify_attendees(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', '')
		self.assertFalse(succ)


	# Posting a comment!
	#def comment(self.ctx, user_id, event_id, title, comment):
	def test_comment_bad_user_id(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = comments.comment(self.ctx, None, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = comments.comment(self.ctx, '', 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = comments.comment(self.ctx, None, 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = comments.comment(self.ctx, 'Ben', '', event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = comments.comment(self.ctx, 'Ben', None, event_id, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_comment_bad_event_id(self):
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', 555, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_comment_bad_title(self):
		# Test empty string as well as None.
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, '', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, None, 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_comment_bad_comment(self):
		# Test empty string as well as None.
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, '', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, None, 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_comment_no_event_exists(self):
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', 555555, 'Coffee before work', 'Hello, world!')
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.NOT_FOUND)

	def test_comment(self):
		friend_id = self.friend_ids[0]
		fctx = FalseSecurityContext(cur)
		fctx.user_id = friend_id

		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = comments.comment(self.ctx, 'Ben', 'Rooke', event_id, 'Coffee before work', 'Hello, world!')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])


if __name__ == '__main__':
	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()
