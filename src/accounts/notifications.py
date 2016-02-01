import psycopg2
import logging
import json

from intertwine import response
from intertwine import strings

def notifications(ctx):
        if ctx is None:
                return response.block(error=strings.VALUE_ERROR, code=500)
  
        query = "SELECT id, message, payload, sent_time FROM notifications WHERE notifier_id=%s ORDER BY sent_time DESC LIMIT 10"
        try:
                ctx.cur.execute(query, (ctx.user_id,))
        except Exception as exc:
                logging.error('failed to retrieve list of notifications for user %d', ctx.user_id)
        rows = ctx.cur.fetchall()
        notifs = [{'id':row[0], 'message':row[1], 'payload':json.loads(row[2]), 'sent_time':str(row[3])} for row in rows]
        return response.block(payload=notifs)
