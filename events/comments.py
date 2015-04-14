import psycopg2

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
		user["id"] = row[1]
		user["first"] = row[2]
		user["last"] = row[3]
		user["email"] = row[4]
		user["facebook_id"] = row[5]
		comment["user"] = user
		comment["id"] = row[0]
		comment["comment"] = row[6]
		comments.append(comment)
	return comments

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
	return {'success':True}
