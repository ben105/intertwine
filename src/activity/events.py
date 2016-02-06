from intertwine.activity import comments
from intertwine.activity import dates
from intertwine.accounts import accounts
from intertwine import response
from intertwine import strings
from intertwine import push
from intertwine import util

import re
import logging
import psycopg2


def insert_event_date(ctx, event_id, date):
	if not date:
		err_msg = 'failed trying to insert event date with None date'
		logging.error(err_msg)
		raise ValueError(err_msg)
	query = """
	INSERT INTO 
		event_dates 
	(accounts_id, events_id, semesters_id, start_date, start_time, all_day) 
	VALUES
		(%s, %s, %s, %s, %s, %s);
	"""
	try:
		ctx.cur.execute(query, (ctx.user_id, event_id, date.semester_id, date.date, date.time, date.all_day))
	except Exception as exc:
		logging.error('exception raise while trying to insert date for event id %s by user %s', event_id, user_id)
		raise


@util.single_transaction
def create(ctx, title, description, attendees, date=None):
	"""Create an event.

	Keyword arguments:
	  ctx - Intertwine context
	  title -- event title
	  description -- description of the event
	  attendees -- list of account IDs
	  date -- the event date object

	Returns:
	  Intertwine response block, with the new event ID in
	  the payload.
	"""
	user_id = ctx.user_id
	if user_id is None:
		logging.error('failed trying to create an event with None user_id')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not title:
		logging.error('failed to create an event for user %d with no title', user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	if len(attendees) == 0:
		logging.error('failed to create an event for user %d, because 0 attendees specified', user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	first = ctx.first
	last = ctx.last
	logging.debug('creating a new activity for user %d called %s', user_id, title)
	# Add the row to the database.
	#insert into events (title) values ('Roller blades');
	try:
		ctx.cur.execute("INSERT INTO events (title, description, creator) VALUES (%s, %s, %s) RETURNING id;", (title, description, user_id))
	except psycopg2.IntegrityError as exc:
		logging.error('exception raised, integreity error, while trying to insert activity %s for user %d', title, user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	except Exception as exc:
		logging.error('exception raised while trying to insert user\'s %d activity (%s) into the database', user_id, title)
		return response.block(error=strings.SERVER_ERROR, code=500)
	event_id = ctx.cur.fetchone()[0]

	# Attempt to set the event date, if one exists. 
	if date:
		# Insert the date into the database.
		try:
			insert_event_date(ctx, event_id, date)
		except ValueError as ve:
			logging.error('bad information passed to insert_event_date: %s', ve)
			return response.block(error=strings.SERVER_ERROR, code=500)
		except Exception as exc:
			logging.error(exc)
			return response.block(error=stings.SERVER_ERROR, code=500)

	for user in attendees:
		try:
			notifInfo = {'event_id':event_id, 'action':push.JUMP_TO}
			if date:
				# Because a date exists, we will need to update the push notification to
				# display the time in the message.
				push.push_notification(ctx, user, "{} {} created a new event: {} at {}".format(first, last, title), notifInfo, date)
			else:	
				push.push_notification(ctx, user, "{} {} created a new event: {}".format(first, last, title), notifInfo)
		except Exception as exc:
			logging.error('exception raised trying to send push notification while inserting attendee %s to activity %s\n%s', user, title, str(exc))
	# Add the attendees to the event.	
	attendees.append(user_id)
	for user in attendees:
		try:
			ctx.cur.execute("INSERT INTO event_attendees (attendee_accounts_id, events_id) VALUES (%s, %s);", (user, event_id))
		except Exception as exc:
			logging.error('exception raised while inserting attendee %d to activity %s\n%s', user, title, str(exc))
			return response.block(error=strings.SERVER_ERROR, code=500)
			#return response.block(error=strings.SERVER_ERROR, code=500)
	
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
	if not event_id:
		return response.block(error=strings.VALUE_ERROR, code=500)
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

def response_for_events(ctx, rows):
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

		attendees = get_attendees(ctx, event["id"])
		event["attendees"] = attendees['payload']

		event["comment_count"] = comments.comment_count(ctx, event['id'])

		# Append to the end of events list
		events.append(event)
	return response.block(payload=events)

def get_events_with_user(ctx, user_id):
	# Query for all events for the pair of user IDs
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
		(accounts.id = %s or accounts.id = %s)
	ORDER BY
		events.updated_time DESC;
	"""
	query = """
	SELECT 
		events.id, 
		events.title, 
		events.description, 
		events.creator,
		events.updated_time,
		events.completed
	FROM 
		events 
	WHERE
		events.id in (SELECT DISTINCT events_id
				FROM event_attendees
				WHERE attendee_accounts_id=%s AND
					events_id in (SELECT events_id
							FROM event_attendees
							WHERE attendee_accounts_id=%s))
	ORDER BY
		events.updated_time DESC;
	"""
	try:
		ctx.cur.execute(query, (ctx.user_id, user_id))
	except Exception as exc:
		logging.error(
			'exception raised trying to retrieve list of events for paired user %d and user %d', ctx.user_id, user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	return response_for_events(ctx, rows)

def get_events_for_user(ctx, user_id):
	# Query for all events for the user ID
	if user_id is None:
		return response.block(error=strings.VALUE_ERROR, code=500)
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
		ctx.cur.execute(query, (user_id,))
	except Exception as exc:
		logging.error('exception raised trying to retrieve list of events for user %d', user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	return response_for_events(ctx, rows)

def get_events(ctx):
	"""Get the list of events for a user ID.

	Keyword arguments:
	  ctx - Intertwine context

	Returns:
	  Intertwine response block with a list of events
	  in the payload.
	"""
	return get_events_for_user(ctx, ctx.user_id)

def delete(ctx, event_id):
	"""Delete an event from the events table, given
	an event ID.

	Keyword arguments:
	  ctx - Intertwine context
	  event_id - integer uniquely indentifying the event

	Response:
	  Intertwine response block.
	"""
	if event_id is None:
		return response.block(error=strings.VALUE_ERROR, code=500)
	query = 'DELETE FROM events WHERE events.id = %s RETURNING *;'
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised when user %d trying to delete event %d', ctx.user_id, event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		return response.block(error=strings.NOT_FOUND, code=404)
	return response.block()

def complete(ctx, event_id, title):
	"Complete an event given an event ID"
	if ctx.user_id is None:
		return response.block(error=strings.VALUE_ERROR, code=500)
	if not event_id or not title:
		return response.block(error=strings.VALUE_ERROR, code=500)
	query = 'UPDATE events SET completed=true, updated_time=now() WHERE id=%s and completed=false RETURNING *;'
	try:
		ctx.cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised when user %d trying to complete an event %d', ctx.user_id, event_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		return response.block(error=strings.NOT_FOUND, code=404)
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
			push.push_notification(ctx, account_id, msg, {'event_id':event_id, 'action':push.JUMP_TO})
	return response.block()




def add_attendees(ctx, event_id, attendees):
	query = """
	INSERT INTO 
	event_attendees (events_id, attendee_accounts_id)
	VALUES          (%s, %s);
	"""
	for attendee in attendees:
		account_id = attendee['id']
		try:
			ctx.cur.execute(query, (event_id, account_id))
		except Exception as exc:
			return response.block(error=strings.SERVER_ERROR, code=500)

def remove_attendees(ctx, event_id, attendees):
	#ids = ['attendee_accounts_id='+str(attendee['id']) for attendee in attendees]
	ids_condition = ['attendee_accounts_id=%s'] * len(attendees)
	query = """
	DELETE FROM
		event_attendees
	WHERE
		events_id=%s and ({});
	""".format(' or '.join(ids_condition))
	try:
		arg_tuple = (event_id,) + tuple([attendee['id'] for attendee in attendees])
		ctx.cur.execute(query, arg_tuple )
	except Exception as exc:
		return response.block(error=strings.SERVER_ERROR, code=500)

def edit_date(ctx, event_id, date):
	pass

def edit_title(ctx, event_id, title):
	if not event_id or not title:
		return response.block(error=strings.SERVER_ERROR, code=500)
	query = 'UPDATE events SET title = %s WHERE id=%s;'
	try:
		ctx.cur.execute(query, (title, event_id))
	except Exception as exc:
		return response.block(error=strings.SERVER_ERROR, code=500)

def edit_location(ctx, event_id, location):
	pass

def push_invited(ctx, event_id, title, invited):
	first = ctx.first
	last = ctx.last
	for attendee in invited:
		user = attendee['id']
		try:
        		notifInfo = {'event_id':event_id, 'action':push.JUMP_TO}
        		push.push_notification(ctx, user, "{} {} invited you to join, {}".format(first, last, title), notifInfo)
		except Exception as exc:
			logging.error('exception raised trying to send push notification while adding attendee %d to activity %s\n%s', user, title, str(exc))	

@util.single_transaction
def edit(ctx, event_id, title, new_title, date, invited, uninvited):
	# Basically, we are going to make edits for any
	# key-value pair we find.
	if invited is not None:
		err = add_attendees(ctx, event_id, invited)
		if err:
			return err
		else:
			push_invited(ctx, event_id, title, invited)
	if uninvited is not None:
		err = remove_attendees(ctx, event_id, uninvited)
		if err:
			return err
	if date is not None:
		err = edit_date(ctx, event_id, date)
		if err:
			return err
	if new_title is not None:
		err = edit_title(ctx, event_id, new_title)
		if err:
			return err
	return response.block()

