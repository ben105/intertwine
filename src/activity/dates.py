from datetime import datetime
import json
import pytz


class EventDate(object):
	def __init__(self, json_body):
		self.time = None	# Because there might not be a specific time set.
		self.semester = None
		self.semester_id = None 
		self.all_day = False
		try:
			self.extract_date(json_body)
		except pytz.exceptions.UnknownTimeZoneError as err:
			raise RuntimeError('unknown timezone in json  body {}'.format(json_body))
		except ValueError as ve:
			# Failed to parse the JSON.
			raise RuntimeError('could not parse the JSON body {}'.format(json_body))
		except KeyError as ke:
			# The JSON body didn't have exactly what I expected.
			raise RuntimeError('key error parsing JSON body {}'.format(json_body))
		if self.semester == 'Morning':
			self.semester_id = 1
		elif self.semester == 'Afternoon':
			self.semester_id = 2
		elif self.semester == 'Evening':
			self.semester_id = 3

	def convert_to_utc(self, timestamp, timezone):
		"""
		Raises:
		  UnknownTimeZoneError: If the timezone provided is not valid.
		"""
		tz_timestamp = pytz.timezone(timezone).localize(timestamp)
		# timestamp = timestamp.replace(tzinfo=pytz.timezone(timezone))
		return tz_timestamp.astimezone(pytz.timezone('UTC'))

	def string(self):
		s = self.date
		if self.time:
			s = s + ' ' + self.time
		return s

	def extract_date(self, json_body):
		"""
		Raises:
		  KeyError:
		  UnknownTimeZoneError: If the timezone provided is not valid.
		  ValueError:
		"""
		body = json.loads(json_body)
		date = body['start_date']
		time = body.get('start_time')
		tz = body['timezone']

		if not date:
			return

		# Combine the date and time, if there exists a time.
		if not time:
			# Check for semester. And all day boolean.
			self.semester = body.get('semester_id')
			# Semester trumps all day.
			if self.semester:
				self.all_day = False
			else:
				self.all_day = body['all_day']
			self.date = date

		else:
			timestamp = datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S')
			# Use the timezone coming in as an indicator of how to
			# convert to UTC. I will be using UTC dates in my database.
			utctime = self.convert_to_utc(timestamp, tz)
			# Convert the timestamp back into a str.
			utc_str = utctime.strftime('%Y-%m-%d %H:%M:%S')
			date_tuple = utc_str.split(' ')
			self.time = date_tuple[1]
			self.date = date_tuple[0]
