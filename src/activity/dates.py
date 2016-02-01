from datetime import datetime
import json
import pytz


class EventDate(object):
	def __init__(self, json_body):
		self.time = None	# Because there might not be a specific time set.
		self.semester = None
		self.all_day = False
		try:
			self.extract_date(json_body)
		except pytz.exceptions.UnknownTimeZoneError as err:
			pass
		except ValueError as ve:
			# Failed to parse the JSON.
			pass
		except KeyError as ke:
			# The JSON body didn't have exactly what I expected.
			pass

	def convert_to_utc(self, timestamp, timezone):
		"""
		Raises:
		  UnknownTimeZoneError: If the timezone provided is not valid.
		"""
		now = datetime.now()
		now = now.replace(tzinfo=pytz.timezone(timezone))
		return now.astimezone(pytz.timezone('UTC'))

	def extract_date(self, json_body):
		"""
		Raises:
		  KeyError:
		  UnknownTimeZoneError: If the timezone provided is not valid.
		  ValueError:
		"""
		body = json.loads(json_body)
		date = body['date']
		time = body.get('time')
		tz = body['timezone']

		# Combine the date and time, if there exists a time.
		if not time:
			# Check for semester. And all day boolean.
			self.semester = body.get('semester')
			# Semester trumps all day.
			if self.semester:
				self.all_day = False
			else:
				self.all_day = body['all_day']
			# Use this time value so the following function will work.
			time = '00:00:00'
		timestamp = '{0} {1}'.format(date, time)
		timestamp = datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S')

		# Use the timezone coming in as an indicator of how to
		# convert to UTC. I will be using UTC dates in my database.
		utctime = self.convert_to_utc(timestamp, tz)

		# Convert the timestamp back into a str.
		utc_str = utctime.strftime('%Y-%m-%d %H:%M:%S')
		date_tuple = utc_str.split(' ')

		# We only want to set the time if there 
		if not self.semester and not self.all_day:
			self.time = date_tuple[1]
		self.date = date_tuple[0]
