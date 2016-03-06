import psycopg2
import logging

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
	if not ctx.user_id:
		logging.error('invalid user ID when trying to retrieve comment count')
		return 0
	if not event_id:
		logging.error('invalid event ID when user %d tried retrieving comment count')
		return 0
	query = 'SELECT count(*) FROM comments_view WHERE events_id=%s;'
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
	if not ctx.user_id:
		logging.error('invalid user ID when trying to retrieve comments')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not event_id:
		logging.error('invalid event ID when user %d tried retrieving comments', ctx.user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
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
		comments_view as c,
		accounts as a
	WHERE
		a.id = c.accounts_id and
		events_id=%s
	ORDER BY c.created_time ASC;
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
		user["id"] = row[1]
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
		event_attendees_view
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

	query = """
	SELECT
		comments.accounts_id
	FROM
		events, comments_view as comments
	WHERE
		events.id = %s and (events.id = comments.events_id);
	"""
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised notifying attendees for event %d', event_id)
		return
			
	rows.extend(ctx.cur.fetchall())
	account_ids = set([row[0] for row in rows])
	account_ids.discard(ctx.user_id)

	if len(account_ids) == 0:
		return False
	for account_id in account_ids:
		msg = "{} posted a comment on {}: {}".format(poster_name, title, comment)
		push.push_notification(ctx, account_id, msg, {'event_id':event_id, 'action':push.SHOW_EVENT_COMMENTS})
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
	if not ctx.user_id:
		logging.error('invalid user ID when trying to post comment')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not ctx.first:
		logging.error('missing first name for user %d when trying to post comment', ctx.user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not ctx.last:
		logging.error('missing last name for  user %d when trying to post comment', ctx.user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)

	if not event_id:
		logging.error('user %d cannot post comment to an invalid event ID', ctx.user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not comment:
		logging.error('user %d cannot post invalid comment to event %d', ctx.user_id, event_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not title:
		logging.error('missing title when user %d tried posting comment to event %d: %s', ctx.user_id, event_id, comment)
		return response.block(error=strings.VALUE_ERROR, code=500)
	query = 'INSERT INTO comments (accounts_id, events_id, comment) VALUES (%s, %s, %s) RETURNING id;'
	try:
		ctx.cur.execute(query, (ctx.user_id, event_id, comment))
	except psycopg2.IntegrityError as exc:
		logging.error('integrity error raised when trying to insert comment "%s" for event %d', comment, ctx.user_id)
		return response.block(error=strings.NOT_FOUND, code=404)
	except Exception as exc:
		logging.error('exception raised trying to insert comment "%s" for event %d', comment, ctx.user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	comment_id = ctx.cur.fetchone()[0]
	notify_attendees(ctx, event_id, title, comment)
	return response.block(payload={
		'comment_id': comment_id
	})
