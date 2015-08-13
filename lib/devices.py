from intertwine import response
from intertwine import strings

def add(ctx, token):
	if not token:
		logging.error('no device token to extract for user %d\n%s', ctx.user_id, str(exc))
		return response.block()
	try:
		ctx.cur.execute("INSERT INTO device_tokens (accounts_id, token) VALUES (%s, %s);", (user_id, psycopg2.Binary(token_data)))
	except Exception as exc:
		logging.error('exception raised trying to insert %d\'s device ID\n%s', ctx.user_id, str(exc))
		return response.block(error=strings.SERVER_ERROR, code=500)
	return response.block()

def get_token(ctx):
	try:
		ctx.cur.execute("SELECT token FROM device_tokens WHERE accounts_id=%s;", (ctx.user_id,))
	except Exception as exc:
		logging.error('exception raised trying to select device token for user %d\n%s', ctx.user_id, str(exc))
		return None
	row = ctx.cur.fetchone()
	return row[0]