import unittest

import intertwine.testdb
from intertwine.activity import events
from intertwine.activity import comments
from intertwine.friends import friends
from intertwine.accounts import accounts
from intertwine import strings

cur = None

class FalseRequest(object):
	def __init__(self, user_id=None, first='', last=''):
		self.headers = { 'user_id':user_id, 'first':first, 'last':last }

def FalseSecurityContext(cur, user_id=None, first='', last=''):
	request = FalseRequest(user_id, first, last)
	return context.SecurityContext(request, cur)

class TestEvents(unittest.TestCase):

	def setUp(self):
		self.ctx = FalseSecurityContext(cur, None, 'Ben', 'Rooke')

		resp = accounts.create_email_account(self.ctx, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
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
		cur.execute('DELETE FROM events;')

	
	#def create(cur, user_id, first, last, title, description, attendees):
	def test_create_bad_user_id(self):
		friend_id = self.friend_ids[0]
		# Include testing for user IDs that don't exist.
		resp = events.create(self.ctx, 'Flames Brunch', '', [friend_id])
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = events.create(cur, 555, 'Ben', 'Rooke', 'Flames Brunch', '', [friend_id])
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_create_bad_title(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, '', '', [friend_id])
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = events.create(self.ctx, None, '', [friend_id])
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_create_bad_attendees(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, '', '', [])
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = events.create(self.ctx, '', '', None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_create(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id = resp['payload']['event_id']
		cur.execute('SELECT title, description, creator FROM events WHERE id=%s;', (event_id,))
		row = cur.fetchone()
		title = row[0]
		description = row[1]
		creator = row[2]
		self.assertEqual(title, 'Flames Brunch')
		self.assertEqual(description, 'It\'s a great restaurant around the corner!')
		self.assertEqual(creator, self.user_id)

	def test_create_duplicate(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id1 = resp['payload']['event_id']
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id2 = resp['payload']['event_id']
		self.assertNotEqual(event_id1, event_id2)


	#def get_attendees(cur, event_id):
	def test_get_attendees_bad_event_id(self):
		# Include the test where the event ID does not exist.
		resp = events.get_attendees(self.ctx, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = events.get_attendees(self.ctx, 555)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_get_attendees(self):
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', friend_ids)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id = resp['payload']['event_id']
		resp = events.get_attendees(self.ctx, event_id)
		attendees = resp['payload']
		self.assertTrue(set(attendees) == set(friend_ids.append(self.user_id)))

		
	#def get_events(cur, user_id):
	def test_get_events_bad_user_id(self):
		fctx = FalseSecurityContext(cur, 555555, 'Ben', 'Rooke')
		resp = events.get_events(fctx)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		fctx = FalseSecurityContext(cur, None, 'Ben', 'Rooke')
		resp = events.get_events(fctx)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_get_events_no_events(self):
		# Test when other people are in events.
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(0, len(resp['payload']))
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		fctx = FalseSecurityContext(cur, friend_id1, 'Rae', 'Jonathans')
		resp = events.create(fctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [friend_id2])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(0, len(resp['payload']))

	def test_get_events_as_an_attendee(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [self.user_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id = resp['payload']['event_id']
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(1, len(resp['payload']))
		event = resp['payload'][0]
		self.assertEqual(event['id'], event_id)
		self.assertEqual(event['title'], 'Flames Brunch')
		self.assertEqual(event['description'], 'It\'s a great restaurant around the corner!')
		self.assertEqual(event['creator']['id'], friend_id)
		self.assertEqual(event['creator']['first'], 'Rae')
		self.assertEqual(event['creator']['last'], 'Jonathans')
		self.assertIsNone(event['creator']['email'])
		self.assertEqual(event['creator']['facebook_id'], 456)
		self.assertTrue(set(event['attendees']) == set([self.user_id, friend_id]))

	def test_get_events_created(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id = resp['payload']['event_id']
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(1, len(resp['payload']))
		event = resp['payload'][0]
		self.assertEqual(event['id'], event_id)
		self.assertEqual(event['title'], 'Flames Brunch')
		self.assertEqual(event['description'], 'It\'s a great restaurant around the corner!')
		self.assertEqual(event['creator']['id'], friend_id)
		self.assertEqual(event['creator']['first'], 'Ben')
		self.assertEqual(event['creator']['last'], 'Rooke')
		self.assertIsNone(event['creator']['facebook_id'])
		self.assertEqual(event['creator']['email'], 'ben_rooke@icloud.com')
		self.assertTrue(set(event['attendees']) == set([self.user_id, friend_id]))

		# Test right comment count too.
		# def comment(cur, user_id, first, last, event_id, title, comment):
		resp = comments.comment(self.ctx, event_id, 'Flames Brunch', 'Want to go tomorrow morning?')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = comments.comment(self.ctx, event_id, 'Flames Brunch', 'Yeah sounds good!')
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(1, len(resp['payload']))
		event = resp['payload'][0]
		self.assertEqual(event['id'], event_id)
		self.assertEqual(event['title'], 'Flames Brunch')
		self.assertEqual(event['description'], 'It\'s a great restaurant around the corner!')
		self.assertEqual(event['creator']['id'], friend_id)
		self.assertEqual(event['creator']['first'], 'Ben')
		self.assertEqual(event['creator']['last'], 'Rooke')
		self.assertIsNone(event['creator']['facebook_id'])
		self.assertEqual(event['creator']['email'], 'ben_rooke@icloud.com')
		self.assertEqual(2, event['comment_count'])
		self.assertTrue(set(event['attendees']) == set([self.user_id, friend_id]))

		
	#def delete(cur, event_id):
	def test_delete_bad_event_id(self):
		resp = events.delete(self.ctx, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = events.delete(self.ctx, 567890)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_delete_event(self):
		friend_id = self.friend_ids[0]
		resp = events.create(self.ctx, 'Flames Brunch', 'It\'s a great restaurant around the corner!', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertIsNotNone(resp['payload'])
		event_id = resp['payload']['event_id']
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(1, len(resp['payload']))
		resp = events.delete_event(self.ctx, event_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.get_events(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		self.assertEqual(0, len(resp['payload']))
		cur.execute(
			'SELECT count(*) FROM events as e, event_attendees as ea WHERE e.id = ea.events_id and ea.attendee_accounts_id=%s', (self.ctx.user_id,))
		row = cur.fetchone()
		count = int(row[0])
		self.assertEqual(0, count)
		

if __name__ == '__main__':
	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()
