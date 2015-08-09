import intertwine.testdb
from intertwine.activity import events
from intertwine.activity import feed
from intertwine.friends import friends
from intertwine.accounts import accounts
from intertwine import strings


class TestFeed(unittest.TestCase):

	def setUp(self):
		if cur is None:
			raise ValueError('database cursor must be set before running test case')
		resp = accounts.create_email_account(cur, 'ben_rooke@icloud.com', 'Ben', 'Rooke', 'password1')
		self.user_id = resp['payload']['user_id']

		facebook_friends = {'Rae Jonathans':'456', 'Ben Rooke':'123', 'Ashley Sellers':'789'}
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
		cur.execute('DELETE FROM events;')


	#def get_activity(cur, user_id):
	def test_get_activity_bad_user_id(self):
		resp = feed.get_activity(cur, None)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)
		resp = feed.get_activity(cur, 555)
		self.assertFalse(resp['success'])
		self.assertEqual(resp['error'], strings.VALUE_ERROR)

	def test_get_activity_just_friends(self):
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		resp = friends.send_request(cur, friend_id2, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, friend_id1, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, self.user_id, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, friend_id1, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, friend_id2, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(cur, friend_id2, 'Ben', 'Rooke', 'Coffee before work', 'Peets new iced coffee', [friend_id1])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = feed.get_activity(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(1, len(activities))
		activity = activities[0]
		self.assertEqual(activity['id'], event_id)
		self.assertEqual(activity['title'], 'Coffee before work')
		self.assertEqual(activity['description'], 'Peets new iced coffee')
		self.assertEqual(activity['creator']['id'], friend_id2)
		self.assertEqual(activity['creator']['first'], 'Ben')
		self.assertEqual(activity['creator']['last'], 'Rooke')
		self.assertIsNone(activity['creator']['email'])
		self.assertEqual(activity['creator']['facebook_id'], 123)
		self.assertTrue( set(activity['attendees']) == set([friend_id1, friend_id2]) )


	def test_get_activity_stuff_but_not_friends(self):
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		resp = friends.send_request(cur, friend_id2, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, friend_id1, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(cur, friend_id2, 'Ben', 'Rooke', 'Coffee before work', 'Peets new iced coffee', [friend_id1])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = feed.get_activity(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(0, len(activities))

	def test_get_activity_just_you(self):
		friend_id = self.friend_ids[0]
		resp = friends.send_request(cur, self.user_id, friend_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, friend_id, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(cur, self.user_id, 'Ben', 'Rooke', 'Coffee before work', 'Peets new iced coffee', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		event_id = resp['payload']['event_id']
		resp = feed.get_activity(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(1, len(activities))
		activity = activities[0]
		self.assertEqual(activity['id'], event_id)
		self.assertEqual(activity['title'], 'Coffee before work')
		self.assertEqual(activity['description'], 'Peets new iced coffee')
		self.assertEqual(activity['creator']['id'], friend_id2)
		self.assertEqual(activity['creator']['first'], 'Ben')
		self.assertEqual(activity['creator']['last'], 'Rooke')
		self.assertEqual(activity['creator']['email'], 'ben_rooke@icloud.com')
		self.assertIsNone(activity['creator']['facebook_id'])
		self.assertTrue( set(activity['attendees']) == set([friend_id, self.user_id]) )

	def test_get_activity_mixed(self):
		friend_id1 = self.friend_ids[0]
		friend_id2 = self.friend_ids[1]
		resp = friends.send_request(cur, friend_id2, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, friend_id1, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, self.user_id, friend_id1)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, friend_id1, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.send_request(cur, friend_id2, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = friends.accept_request(cur, self.user_id, friend_id2)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(cur, friend_id1, 'Rae', 'Jonathans', 'Coffee before work', 'Peets new iced coffee', [friend_id2])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = events.create(cur, self.user_id, 'Ben', 'Rooke', 'Morning Hike', 'Meet at Castle Rock!', [friend_id])
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		resp = feed.get_activity(cur, self.user_id)
		self.assertTrue(resp['success'])
		self.assertIsNone(resp['error'])
		activities = resp['payload']
		self.assertEqual(2, len(activities))
		titles = [activity['title'] for activity in activities]
		descriptions = [activity['description'] for activity in activities]
		self.assertTrue( set(titles) == set(['Coffee before work', 'Morning Hike']))
		self.assertTrue( set(descriptions) == set(['Peets new iced coffee', 'Meet at Castle Rock!']))


if __name__ == '__main__':
	cur = intertwine.testdb.start()
	
	try:
		unittest.main()
	except Exception as exc:
		print(exc)

	intertwine.testdb.stop()
	cur.connection.close()