from intertwine import response
from intertwine import strings
import logging
import psycopg2

def add(ctx, token):
	if not token:
		logging.error('no device token to extract for user %d', ctx.user_id)
		return response.block()
	try:
		ctx.cur.execute("INSERT INTO device_tokens (accounts_id, token) VALUES (%s, %s);", (ctx.user_id, psycopg2.Binary(token)))
	except Exception as exc:
		logging.error('exception raised trying to insert %d\'s device ID\n%s', ctx.user_id, str(exc))
		return response.block(error=strings.SERVER_ERROR, code=500)
	return response.block()

def get_token(cur, user_id):
	try:
		cur.execute("SELECT token FROM device_tokens WHERE accounts_id=%s;", (user_id,))
	except Exception as exc:
		logging.error('exception raised trying to select device token for user %d\n%s', user_id, str(exc))
		return None
	rows = cur.fetchall()
	if rows is None:
		return None
	return [row[0] for row in rows]
