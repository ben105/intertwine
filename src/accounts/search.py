from intertwine import response
from intertwine import strings
import logging

def find(ctx, name):
	"""Given a user ID, search for this particular person.
	Results should vary depending on if the person is blocked,
	or if there is a preference to show someone higher up on 
	the list, etc.

	Keyword arguments:
	  ctx - Intertwine context
	  name - name of the person we're searching for

	Returns:
	  Python dictionary representing the success of the request.
	"""
	user_id = ctx.user_id
	logging.debug('user ID %d searching for %s', user_id, name)
	find_query = """
	SELECT
		first,
		last,
		facebook_id,
		email,
		accounts.id,
		(SELECT count(*) FROM friend_requests WHERE requester_accounts_id = %(user_id)s and requestee_accounts_id = accounts.id) AS requestee
	FROM
		accounts_view as accounts
	WHERE
		(first ilike %(like1)s or
		last ilike %(like2)s) and accounts.id <> %(user_id2)s and accounts.id not in 
		(SELECT
			friend_accounts_id
		FROM
			friends_view
		WHERE
			accounts_id = %(user_id3)s);
	"""
	try:
		logging.debug('user ID %d running FIND query', user_id)
		ctx.cur.execute(find_query, {'user_id':user_id, 'like1':name+'%', 'like2':name+'%', 'user_id2':user_id, 'user_id3':user_id})
	except Exception as exc:
		logging.error('failed to search for %s, request made by user ID %d\nException: %s', name, user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	logging.info('user ID %d running FIND query for name %s. %d results found', user_id, name, len(rows))
	logging.debug('Success FIND query, user ID %d results for search on name %s', user_id, name)
	results = [{'id':str(row[4]), 'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3], 'sent':row[5]} for row in rows]
	return response.block(payload=results)
