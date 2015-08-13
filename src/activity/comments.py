import psycopg2
from intertwine import push
from intertwine import response
from intertwine import strings

def comment_count(ctx, event_id):
	"""Get the number of comments, given an event ID.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id - a unique integer identifing and event

	Returns:
	  The number of comments in the given event.
	"""
	query = 'SELECT count(*) FROM comments WHERE events_id=%s;'
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised trying to retrieve comment count for event %d', event_id)
		return 0
	row = ctx.cur.fetchone()
	return int(row[0])

def get_comments(ctx, event_id):
	"""Getting the comments for a given event ID.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id - a unique integer identifing and event

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
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised retrieving comments for event %d', event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
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

def notify_attendees(ctx, event_id, title, comment):
	"""Notify attendees of the new comment.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id -- integer uniquly indentifing the event
	  title -- the title of the event
	  comment -- the comment (string value)
	"""
	user_id = ctx.user_id
	first = ctx.first
	last = ctx.last
	if not title or not user_id or not event_id or not comment or not first or not last:
		return False
	poster_name = '{} {}'.format(first, last)
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
		ctx.cur.execute(query, (event_id, user_id))
	except Exception as exc:
		logging.error('exception raised notifying attendees for event %d', event_id)
		return
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		return False
	for row in rows:
		account_id = row[0]
		msg = "{} posted a comment on {}: {}".format(poster_name, title, comment)
		push.push_notification(ctx.cur, account_id, msg)
	return True

def comment(ctx, event_id, title, comment):
	"""Posting a comment to an event.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id - unique integer identifing event
	  title - the title of the event
	  comment - comment string

	Returns:
	  Intertwine response block.
	"""
	query = 'INSERT INTO comments (accounts_id, events_id, comment) VALUES (%s, %s, %s) RETURNING id;'
	try:
		ctx.cur.execute(query, (ctx.user_id, event_id, comment))
	except Exception as exc:
		logging.error('exception raised trying to insert comment "%s" for event %d', comment, ctx.user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	notify_attendees(ctx.cur, ctx.user_id, ctx.first, ctx.last, event_id, title, comment)
	comment_id = ctx.cur.fetchone()[0]
	return response.block(payload={
		'comment_id': comment_id
	})
