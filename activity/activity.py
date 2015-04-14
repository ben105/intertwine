import intertwine.events.events as eve
import psycopg2

def get_activity(cur, user_id):
	# Build the query
	query = """
	SELECT
		events.id,
		events.title,
		events.description,
		events.creator,
		events.updated_time
	FROM
		friends,
		event_attendees,
		events
	WHERE
		accounts_id = %s and
		friend_accounts_id = event_attendees.attendee_accounts_id and
		event_attendees.events_id = events.id;
	"""
	try:
		cur.execute(query, (user_id,))
	except Exception as exc:
		print("Exception occured when trying to populate the activity feed:\n{}".format(exc))
		return
	events = []
	rows = cur.fetchall()
	for row in rows:
		event = {}
		event["id"] = row[0]
		event["title"] = row[1]
		event["description"] = row[2]
		event["creator"] = eve.get_creator(cur, row[3])
		event["updated_time"] = str(row[4])
		event["attendees"] = eve.get_attendees(cur, row[0])
		events.append(event)
	return events	
