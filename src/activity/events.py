from intertwine.activity import comments
from intertwine.accounts import accounts
import logging
from intertwine import response
from intertwine import strings
from intertwine import push

def single_transaction(func):
	def inner(*argv, **kwargs):
		assert(len(argv)>0)
		ctx = argv[0]
		ctx.cur.connection.autocommit = False
		success = func(*argv, **kwargs)
		if type(success) is bool and success == False:
			logging.error('single transaction failed, and is rolling back')
			ctx.cur.rollback()
		else:
			logging.debug('single transaction completed')
			ctx.cur.connection.commit()
		ctx.cur.connection.autocommit = True
		return success
	return inner

@single_transaction
def create(ctx, title, description, attendees):
	"""Create an event.

	Keyword arguments:
	  ctx - Intertwine context
	  title -- event title
	  description -- description of the event
	  attendees -- list of account IDs

	Returns:
	  Intertwine response block, with the new event ID in
	  the payload.
	"""
	user_id = ctx.user_id
	first = ctx.first
	last = ctx.last
	logging.debug('creating a new activity for user %d called %s', user_id, title)
	# Add the row to the database.
	#insert into events (title) values ('Roller blades');
	try:
		ctx.cur.execute("INSERT INTO events (title, description, creator) VALUES (%s, %s, %s) RETURNING id;", (title, description, user_id))
	except Exception as exc:
		logging.error('exception raised while trying to insert user\'s %d activity (%s) into the database', user_id, title)
		return response.block(error=strings.SERVER_ERROR, code=500)
	event_id = ctx.cur.fetchone()[0]

	for user in attendees:
		try:
			push.push_notification(ctx.cur, user, "{} {} created a new event: {}".format(first, last, title))
		except Exception as exc:
			logging.error('exception raised trying to send push notification while inserting attendee %d to activity %s\n%s', user, title, str(exc))
	# Add the attendees to the event.	
	attendees.append(user_id)
	for user in attendees:
		try:
			ctx.cur.execute("INSERT INTO event_attendees (attendee_accounts_id, events_id) VALUES (%s, %s);", (user, event_id))
		except Exception as exc:
			logging.error('exception raised while inserting attendee %d to activity %s\n%s', user, title, str(exc))
			return response.block(error=strings.SERVER_ERROR, code=500)
			#return response.block(error=strings.SERVER_ERROR, code=500)
	# TODO: Return success or error
	return response.block(payload={
		'event_id': event_id
	})

def get_attendees(ctx, event_id):
	"""Get a list of the attendees for a
	given event ID.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id - integer uniquely identifying event

	Returns:
	  Intertwine response block with the list of attendees
	  in the payload.
	"""
	query = """
	SELECT 
		accounts.first, 
		accounts.last, 
		accounts.email, 
		accounts.facebook_id, 
		accounts.id 
	FROM 
		event_attendees, 
		accounts 
	WHERE 
		event_attendees.attendee_accounts_id=accounts.id and 
		event_attendees.events_id=%s;
	"""
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised attempting to get list of attendees for event %d', event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	results = ctx.cur.fetchall()
	attendees = [{"first":a[0], "last":a[1], "email":a[2], "facebook_id":a[3], "id":a[4]} for a in results] 
	return response.block(payload=attendees)

def get_events(ctx):
	"""Get the list of events for a user ID.

	Keyword arguments:
	  ctx - Intertwine context

	Returns:
	  Intertwine response block with a list of events
	  in the payload.
	"""
	# Query for all events for the user ID
	query = """
	SELECT 
		events.id, 
		events.title, 
		events.description, 
		events.creator,
		events.updated_time,
		events.completed
	FROM 
		accounts, 
		events, 
		event_attendees 
	WHERE 
		accounts.id = event_attendees.attendee_accounts_id and 
		event_attendees.events_id = events.id and 
		accounts.id = %s
	ORDER BY
		events.updated_time DESC;
	"""
	try:
		ctx.cur.execute(query, (ctx.user_id,))
	except Exception as exc:
		logging.error('exception raised trying to retrieve list of events for user %d', ctx.user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	events = []
	for row in rows:
		# Get the creator's account information
		creator = accounts.user_info(ctx.cur, row[3])
		if creator is None:
			logging.error('could not find creator for event %d', row[3])
			continue
		event = {}
		event["id"] = row[0]
		event["title"] = row[1]
		event["description"] = row[2]
		event["creator"] = creator
		event["updated_time"] = str(row[4]).split('.')[0]
		event["attendees"] = get_attendees(ctx.cur, event["id"])
		event["comment_count"] = comments.comment_count(ctx, event["id"])
		event["completed"] = row[5]
		# Append to the end of events list
		events.append(event)
	return response.block(payload=events)

def delete(ctx, event_id):
	"""Delete an event from the events table, given
	an event ID.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id - integer uniquely indentifying the event

	Response:
	  Intertwine response block.
	"""
	query = 'DELETE FROM events WHERE events.id = %s;'
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised when user %d trying to delete event %d', ctx.user_id, event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	return response.block()

def complete(ctx, event_id, title):
	"Complete an event given an event ID"
	query = 'UPDATE events SET completed=true, updated_time=now() WHERE id=%s;'
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised when user %d trying to complete an event %d', ctx.user_id, event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	query = """
	SELECT
		attendee_accounts_id
	FROM
		event_attendees
	WHERE
		events_id = %s and attendee_accounts_id <> %s;
	"""
	try:
		ctx.cur.execute(query, (event_id, ctx.user_id))
	except Exception as exc:
		logging.error('exception raised notifying users of a completed event %d', event_id)
		return
	rows = ctx.cur.fetchall()
	if len(rows) > 0:
		for row in rows:
			account_id = row[0]
			msg = '{} {} marked {} as complete!'.format(ctx.first, ctx.last, title)
			push.push_notification(ctx.cur, account_id, msg)
	return response.block()
