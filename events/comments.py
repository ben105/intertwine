import psycopg2
from intertwine import push

def comment_count(cur, event_id):
	query = """
	SELECT
		count(*)
	FROM
		comments
	WHERE
		events_id=%s;
	"""
	try:
		cur.execute(query, (event_id,))
	except Exception as exc:
		print(exc)
		return
	row = cur.fetchone()
	return { "comment_count": int(row[0]) }

def get_comments(cur, event_id):
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
		print(exc)
		return
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
	return comments

def event_title(cur, event_id):
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
		print(exc)
		return
	row = cur.fetchone()
	return row[0]

def notify_attendees(cur, user_id, event_id, comment):
	poster_name = push.name(cur, user_id)
	title = event_title(cur, event_id)
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
		print(exc)
		return
	rows = cur.fetchall()
	for row in rows:
		account_id = row[0]
		msg = "{} posted a comment on {}: {}".format(poster_name, title, comment)
		push.push_notification(cur, account_id, msg)

def add_comment(cur, user_id, event_id, comment):
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
		print(exc)
		return
	notify_attendees(cur, user_id, event_id, comment)
	return {'success':True}
