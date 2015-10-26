import unittest
import logging

import intertwine.testdb
from intertwine.activity import events
from intertwine.activity import activity
from intertwine.friends import friends
from intertwine.accounts import accounts
from intertwine import strings
from intertwine import context


cur = None

class FalseRequest(object):
	def __init__(self, user_id=None, first='', last=''):
		self.headers = { 'user_id':user_id, 'first':first, 'last':last }

def FalseSecurityContext(cur, user_id=None, first='', last=''):
	request = FalseRequest(user_id, first, last)
	return context.SecurityContext(request, cur)

class TestFeed(unittest.TestCase):

	def setUp(self):
		if cur is None:
			raise ValueError('database cursor must be set before running test case')
		self.ctx = FalseSecurityContext(cur, None, 'Ben', 'Rooke')
		resp = accounts.create_email_account(self.ctx, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		self.ctx.user_id = resp['payload']['user_id']

		facebook_friends = {'Rae Jonathans':'456', 'Ashley Sellers':'789'}
		self.friend_ids = []
		self.friends_dict = {}
		for k, v in facebook_friends.iteritems():
			name_components = k.split()
			first = name_components[0]; 
			last = name_components[1]
			resp = accounts.sign_in_facebook(self.ctx, v, first, last)
			friend_id = resp['payload']['user_id']
			self.friend_ids.append(friend_id)
			self.friends_dict[friend_id] = {'first':first, 'last':last, 'facebook_id':v}

	def tearDown(self):
		cur.execute('DELETE FROM accounts;')
		cur.execute('DELETE FROM friends;')
		cur.execute('DELETE FROM friend_requests;')
		cur.execute('DELETE FROM events;')


	#def get_activity(cur, user_id):
	def test_get_activity_bad_user_id(self):
		fctx = FalseSecurityContext(cur, None, 'Ben', 'Rooke')
		resp = activity.get_activity(fctx)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_get_activity_just_friends(self):
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		fctx1 = FalseSecurityContext(cur, friend_id1, self.friends_dict[friend_id1]['first'], self.friends_dict[friend_id1]['last'])
		fctx2 = FalseSecurityContext(cur, friend_id2, self.friends_dict[friend_id2]['first'], self.friends_dict[friend_id2]['last'])
		resp = friends.send_request(fctx2, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx1, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(self.ctx, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx1, self.ctx.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(fctx2, self.ctx.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(fctx2, 'Coffee before work', 'Peets new iced coffee', [friend_id1])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = activity.get_activity(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(1, len(activities))
		act = activities[0]
		self.assertEqual(act['id'], event_id)
		self.assertEqual(act['title'], 'Coffee before work')
		self.assertEqual(act['description'], 'Peets new iced coffee')
		self.assertEqual(act['creator']['id'], friend_id2)
		self.assertEqual(act['creator']['first'], self.friends_dict[friend_id2]['first'])
		self.assertEqual(act['creator']['last'], self.friends_dict[friend_id2]['last'])
		self.assertIsNone(act['creator']['email'])
		self.assertEqual(act['creator']['facebook_id'], self.friends_dict[friend_id2]['facebook_id'])
		attendees = [i['id'] for i in act['attendees']]
		self.assertTrue( set(attendees) == set([friend_id1, friend_id2]) )


	def test_get_activity_stuff_but_not_friends(self):
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		fctx1 = FalseSecurityContext(cur, friend_id1, self.friends_dict[friend_id1]['first'], self.friends_dict[friend_id1]['last'])
		fctx2 = FalseSecurityContext(cur, friend_id2, self.friends_dict[friend_id2]['first'], self.friends_dict[friend_id2]['last'])
		resp = friends.send_request(fctx2, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx1, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(fctx2, 'Coffee before work', 'Peets new iced coffee', [friend_id1])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = activity.get_activity(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(0, len(activities))

	def test_get_activity_just_you(self):
		friend_id = self.friend_ids[0]
		fctx1 = FalseSecurityContext(cur, friend_id, self.friends_dict[friend_id]['first'], self.friends_dict[friend_id]['last'])
		resp = friends.send_request(self.ctx, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx1, self.ctx.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = activity.get_activity(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(1, len(activities))
		act = activities[0]
		self.assertEqual(act['id'], event_id)
		self.assertEqual(act['title'], 'Coffee before work')
		self.assertEqual(act['description'], 'Peets new iced coffee')
		self.assertEqual(act['creator']['id'], self.ctx.user_id)
		self.assertEqual(act['creator']['first'], 'Ben')
		self.assertEqual(act['creator']['last'], 'Rooke')
		self.assertEqual(act['creator']['email'], 'ben_rooke@icloud.com')
		self.assertIsNone(act['creator']['facebook_id'])
		attendees = [i['id'] for i in act['attendees']]
		self.assertTrue( set(attendees) == set([friend_id, self.ctx.user_id]) )

	def test_get_activity_mixed(self):
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		fctx1 = FalseSecurityContext(cur, friend_id1, self.friends_dict[friend_id1]['first'], self.friends_dict[friend_id1]['last'])
		fctx2 = FalseSecurityContext(cur, friend_id2, self.friends_dict[friend_id2]['first'], self.friends_dict[friend_id2]['last'])
		resp = friends.send_request(fctx2, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx1, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(self.ctx, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(fctx1, self.ctx.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(fctx2, self.ctx.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(self.ctx, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(fctx1, 'Coffee before work', 'Peets new iced coffee', [friend_id2])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(self.ctx, 'Morning Hike', 'Meet at Castle Rock!', [friend_id1])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = activity.get_activity(self.ctx)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(2, len(activities))
		titles = [act['title'] for act in activities]
		descriptions = [act['description'] for act in activities]
		self.assertTrue( set(titles) == set(['Coffee before work', 'Morning Hike']))
		self.assertTrue( set(descriptions) == set(['Peets new iced coffee', 'Meet at Castle Rock!']))


if __name__ == '__main__':
	logging.disable(logging.CRITICAL)

	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()
