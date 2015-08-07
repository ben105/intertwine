import intertwine.events.comments as comments
import logging

def single_transaction(func):
	def inner(*argv, **kwargs):
		assert(len(argv)>0)
		cursor = argv[0]
		cursor.connection.autocommit = False
		success = func(*argv, **kwargs)
		if type(success) is bool and success == False:
			logging.error('single transaction failed, and is rolling back')
			cursor.rollback()
		else:
			logging.debug('single transaction completed')
			cursor.connection.commit()
		cursor.connection.autocommit = True
		return success
	return inner

@single_transaction
def create_event(cur, user_id, title, description, attendees):
	logging.debug('creating a new activity for user %d called %s', user_id, title)
	# Add the row to the database.
	#insert into events (title) values ('Roller blades');
	try:
		cur.execute("insert into events (title, description, creator) values (%s, %s, %s) returning id;", (title, description, user_id))
		event_id = cur.fetchone()[0]
	except Exception as exc:
		logging.error('exception raised while trying to insert user\'s %d activity (%s) into the database', user_id, title)
		return False
	# Add the attendees to the event.	
	#insert into event_attendees (attendee_accounts_id, events_id) values (38, 1);
	attendees.append(str(user_id))
	for user in attendees:
		try:
			cur.execute("insert into event_attendees (attendee_accounts_id, events_id) values (%s, %s);", (int(user), event_id))
		except Exception as exc:
			logging.error('exception raised while inserting attendee %d to activity %s', user, title)
			return False
	# TODO: Return success or error
	return {'success':True}

def get_creator(cur, creator_id):
	query = """
	SELECT
		first,
		last,
		email,
		facebook_id
	FROM
		accounts
	WHERE
		accounts.id = %s;
	"""
	try:
		cur.execute(query, (creator_id,))
		creator_row = cur.fetchone()
	except Exception as exc:
		logging.error('exception raised while retrieving creator %d', creator_id)
		return {}
	creator_first = creator_row[0]
	creator_last = creator_row[1]
	creator_email = creator_row[2]
	creator_facebook_id = creator_row[3]
	return {
		'id':creator_id,
		'first':creator_first,
		'last':creator_last,
		'email':creator_email,
		'facebook_id':creator_facebook_id
	}

def get_attendees(cur, event_id): 
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
		cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised attempting to get list of attendees for event %d', event_id)
		return
	results = cur.fetchall()
	attendees = [{"first":a[0], "last":a[1], "email":a[2], "facebook_id":a[3], "id":a[4]} for a in results] 
	return attendees

def get_events(cur, user_id):
	# Query for all events for the user ID
	query = """
	SELECT 
		events.id, 
		events.title, 
		events.description, 
		events.creator,
		events.updated_time 
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
		cur.execute(query, (user_id,))
	except Exception as exc:
		logging.error('exception raised trying to retrieve list of events for user %d', user_id)
		return []
	rows = cur.fetchall()
	events = []
	for row in rows:
		# Get the creator's account information
		event = {}
		event["id"] = row[0]
		event["title"] = row[1]
		event["description"] = row[2]
		event["creator"] = get_creator(cur, row[3])
		event["updated_time"] = str(row[4]).split('.')[0]
		event["attendees"] = get_attendees(cur, event["id"])
		event["comment_count"] = comments.comment_count(cur, event["id"])
		# Append to the end of events list
		events.append(event)
	return events	

def delete_event(cur, event_id):
	query = """
	DELETE FROM 
		events
	WHERE
		events.id = %s
	"""
	try:
		cur.execute(query, (event_id,))
	except Exception as exc:
		logging.error('exception raised trying to delete event %d', event_id)
		return {}
	return { 'success':True }