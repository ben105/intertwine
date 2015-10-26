from intertwine.accounts import accounts
from intertwine.activity import events
from intertwine.activity import comments
from intertwine import response
from intertwine import strings

import psycopg2
import logging

def get_activity(ctx):
	"""Retrieve the list of activities, as defined by your
	social network (the people you are friends with).

	Keyword arguments:
	  ctx - Intertwine context

	Response:
	  Intertwine response block, with a list of activities as
	  the payload.
	"""
	user_id = ctx.user_id
	if user_id is None:
		return response.block(error=strings.VALUE_ERROR, code=500)
	# Build the query
	logging.debug('fetching activities for user %d', user_id)
	query = """
	SELECT DISTINCT
		events.id,
		events.title,
		events.description,
		events.creator,
		events.updated_time,
		events.completed
	FROM
		events
	INNER JOIN 	event_attendees
	ON 		event_attendees.events_id = events.id
	INNER JOIN 	friends
	ON 		friends.friend_accounts_id = event_attendees.attendee_accounts_id
	WHERE
		accounts_id = %s and completed=false
	ORDER BY
		updated_time DESC;
	"""
	try:
		ctx.cur.execute(query, (user_id,))
	except Exception as exc:
		logging.error('exception raised while trying to populate the activity feed for user %d', user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	activities = []
	rows = ctx.cur.fetchall()
	for row in rows:
		event = {}
		event["id"] = row[0]
		event["title"] = row[1]
		event["description"] = row[2]
		event["creator"] = accounts.user_info(ctx.cur, row[3])
		event["updated_time"] = str(row[4])
		event["completed"] = row[5]
		resp = events.get_attendees(ctx, row[0])
		if resp['error'] is not None:
			return resp
		event["attendees"] = resp['payload']
		event["comment_count"] = comments.comment_count(ctx, event["id"])
		activities.append(event)
	logging.debug('fetched %d activities for user %d', len(activities), user_id)
	return response.block(payload=activities)	
