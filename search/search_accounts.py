
def find(cursor, str):
	find_query = """
	SELECT
		first,
		last,
		facebook_id,
		email
	FROM
		accounts
	WHERE
		first ilike %(like1)s or
		last ilike %(like2)s;
	"""
	cursor.execute(find_query, {'like1':str+'%', 'like2':str+'%'})
	rows = cursor.fetchall()
	return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
