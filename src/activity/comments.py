import psycopg2
from intertwine import push
from intertwine import response
from intertwine import strings

def comment_count(cur, event_id):
	"""Get the number of comments, given an event ID.

	Keyword arguments:
	  cur -- cursor to the database
	  event_id -- a unique integer identifing and event

	Returns:
	  The number of comments in the given event.
	"""
	query = 'SELECT count(*) FROM comments WHERE events_id=%s;'
	try:
		cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised trying to retrieve comment count for event %d', event_id)
		return {}
	row = cur.fetchone()
	return int(row[0])

def get_comments(cur, event_id):
	"""Getting the comments for a given event ID.

	Keyword arguments:
	  cur -- cursor to the database
	  event_id -- a unique integer identifing and event

	Returns:
	  An Intertwine response block, with a dictionary
	  of comments in the payload.
	"""	
	query = """
	SELECT
		c.id,
		a.id,
		a.first,
		a.last,
		a.email,
		a.facebook_id,
		comment
	FROM
		comments as c,
		accounts as a
	WHERE
		a.id = c.accounts_id and
		events_id=%s;
	"""
	try:
		cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised retrieving comments for event %d', event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = cur.fetchall()
	comments = []
	for row in rows:
		comment = {}
		user = {}
		user["id"] = str(row[1])
		user["first"] = row[2]
		user["last"] = row[3]
		user["email"] = row[4]
		user["facebook_id"] = row[5]
		comment["user"] = user
		comment["id"] = row[0]
		comment["comment"] = row[6]
		comments.append(comment)
	return response.block(payload=comments)

def event_title(cur, event_id):
	"""Getting the event title for a given event ID.

	Keyword arguments:
	  cur -- cursor to the database
	  event_id -- a unique integer identifing and event

	Returns:
	  An Intertwine response block, with an event title
	  in the payload.
	"""
	query = """
	SELECT
		title
	FROM
		events
	WHERE
		id = %s;
	"""
	try:
		cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised retrieving event %d title', event_id)
		return ''
	row = cur.fetchone()
	return row[0]

def notify_attendees(cur, user_id, event_id, title, comment):
	"""Notify attendees of the new comment.

	Keyword arguments:
	  cur -- cursor to the database
	  user_id -- the user posting the comment
	  event_id -- integer uniquly indentifing the event
	  title -- the title of the event
	  comment -- the comment (string value)
	"""
	poster_name = push.name(cur, user_id)
	query = """
	SELECT
		attendee_accounts_id
	FROM
		event_attendees
	WHERE
		events_id = %s and 
		attendee_accounts_id <> %s;
	"""
	try:
		cur.execute(query, (event_id, user_id))
	except Exception as exc:
		logging.error('exception raised notifying attendees')
		return
	rows = cur.fetchall()
	for row in rows:
		account_id = row[0]
		msg = "{} posted a comment on {}: {}".format(poster_name, title, comment)
		push.push_notification(cur, account_id, msg)

def add_comment(cur, user_id, event_id, comment):
	"""Posting a comment to an event.

	Keyword arguments:
	  cur -- cursor to database
	  user_id -- the user posting the comment
	  event_id -- unique integer identifing event
	  comment -- comment string

	Returns:
	  Intertwine response block.
	"""
	query = """
	INSERT INTO
		comments
	(accounts_id, events_id, comment)
	VALUES
		(%s, %s, %s);
	"""
	try:
		cur.execute(query, (user_id, event_id, comment))
	except Exception as exc:
		logging.error('exception raised trying to insert comment "%s" for event %d', comment, user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	notify_attendees(cur, user_id, event_id, comment)
	return response.block()
