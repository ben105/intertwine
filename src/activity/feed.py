from intertwine.events import events
from intertwine import response
from intertwine import strings

import psycopg2
import logging

def get_activity(cur, user_id):
	"""Retrieve the list of activities, as defined by your
	social network (the people you are friends with).

	Keyword arguments:
	  cur -- cursor to the database
	  user_id -- user who's requesting activites

	Response:
	  Intertwine response block, with a list of activities as
	  the payload.
	"""
	# Build the query
	logging.debug('fetching activities for user %d', user_id)
	query = """
	SELECT DISTINCT
		events.id,
		events.title,
		events.description,
		events.creator,
		events.updated_time
	FROM
		events
	INNER JOIN 	event_attendees
	ON 		event_attendees.events_id = events.id
	INNER JOIN 	friends
	ON 		friends.friend_accounts_id = event_attendees.attendee_accounts_id
	WHERE
		accounts_id = %s
	ORDER BY
		updated_time DESC;
	"""
	try:
		cur.execute(query, (user_id,))
	except Exception as exc:
		logging.error('exception raised while trying to populate the activity feed for user %d', user_id)
		return response.block(strings.SERVER_ERROR, code=500)
	activities = []
	rows = cur.fetchall()
	for row in rows:
		event = {}
		event["id"] = row[0]
		event["title"] = row[1]
		event["description"] = row[2]
		event["creator"] = events.get_creator(cur, row[3])
		event["updated_time"] = str(row[4])
		event["attendees"] = events.get_attendees(cur, row[0])
		activities.append(event)
	logging.debug('fetched %d activities for user %d', len(activities), user_id)
	return response.block(payload=activities)	
