from datetime import datetime
import json
import logging
import unittest

from intertwine.activity import dates


class TestEvents(unittest.TestCase):
	def setUp(self):
		# Get the current time.
		self.timestamp = datetime.utcnow()
		date_str = self.timestamp.strftime('%Y-%m-%d %H:%M:%S')
		date_tuple = date_str.split(' '))
		self.json = {
			'date': date_tuple[0],
			'time': date_tuple[1],
			'semester': None,
			'all_day': True,
			'timezone': 'UTC'
		}

	def test_with_no_time(self):
		self.json['time'] = None
		e = dates.EventDate(self.json)
		self.assertIsNone(e.time)
		self.assertEqual(e.date, self.json['date'])

	def test_with_time(self):
		e = dates.EventDate(self.json)
		self.assertIsNotNone(e.time)
		self.assertEqual(self.json['time'], e.time)
		self.assertEqual(self.json['date'], e.time)
		self.assertIsNone(e.semester)
		self.assertIsFalse(e.all_day)

	def test_with_semesters(self):
		self.json['semester'] = 'Morning'
		e = dates.EventDate(self.json)
		self.assertEqual(e.semester, self.json['semester'])
		self.assertIsFalse(e.all_day)
		self.assertIsNone(e.time)

	def test_with_all_day(self):
		self.json['all_day'] = True
		self.json['time'] = None
		e = dates.EventDate(self.json)
		self.assertTrue(e.all_day)
		self.assertIsNone(e.time)

	def test_different_timezone(self):
		self.json['timezone'] = 'America/Los_Angeles'
		e = date.EventDate(self.json)
		self.assertIsNotEqual(e.time, self.json['time'])


if __name__ == '__main__':
	logging.disable(logging.CRITICAL)
	try:
		unittest.main()
	except Exception as exc:
		print(exc)