
def find(cursor, user_id, name):
	find_query = """
	SELECT
		first,
		last,
		facebook_id,
		email,
		accounts.id,
		(SELECT count(*) FROM friend_requests WHERE requester_accounts_id = %(user_id)s and requestee_accounts_id = accounts.id) AS requestee
	FROM
		accounts
	WHERE
		(first ilike %(like1)s or
		last ilike %(like2)s) and accounts.id <> %(user_id2)s and accounts.id not in 
		(SELECT
			friend_accounts_id
		FROM
			friends
		WHERE
			accounts_id = %(user_id3)s);
	"""
	try:
		cursor.execute(find_query, {'user_id':user_id, 'like1':name+'%', 'like2':name+'%', 'user_id2':user_id, 'user_id3':user_id})
		rows = cursor.fetchall()
	except:
		return None
	return [{'account_id':row[4], 'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3], 'sent':row[5]} for row in rows]
