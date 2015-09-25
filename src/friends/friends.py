import psycopg2
import logging

from intertwine import response
from intertwine import strings
from intertwine import util

def purge_blocked(ctx, blocked_user_id):
	if ctx.user_id is None:
		logging.error('failed to purge blocked ID because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if blocked_user_id is None:
		logging.error('failed to purge blocked ID because blocked_user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	delete_query = """
	DELETE FROM blocked_accounts
	WHERE
		accounts_id = %s and
		blocked_accounts_id = %s
	RETURNING *;
	"""
	try:
		ctx.cur.execute(delete_query, (ctx.user_id, blocked_user_id))
	except Exception as exc:
		logging.error('raised exception when user %d tried purging a block on %d\n%s', ctx.user_id, blocked_user_id, str(exc))
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		return response.block(error=strings.NOT_FOUND, code=404)
	return response.block()

# Pending Requests
#
# This query will retirive the list of friends from whom
# you have a pending request.
# It will ignore requests you've previously denied.
def get_pending_requests(ctx):
	if ctx.user_id is None:
		logging.error('failed to get pending requests with ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	pending_requests_query = """
	SELECT
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email,
		accounts.id
	FROM 
		accounts, friend_requests
	WHERE
		friend_requests.denied = false and
		friend_requests.requester_accounts_id = accounts.id and
		friend_requests.requestee_accounts_id = %s;
	"""
	try:
		ctx.cur.execute(pending_requests_query, (ctx.user_id,))
	except Exception as exc:
		logging.error('exception raised retrieving pending requests for user %d, %s', ctx.user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	payload = []
	rows = ctx.cur.fetchall()
	if len(rows):
		payload = [{'account_id':row[4], 'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d getting pending requests', ctx.user_id)
	return response.block(payload=payload)


# Friend suggestions
#
# This query, as of this writing (01/07/15), will use
# this list of Facebook friends to find accounts in 
# the Intertwine database for friend suggestions.
# Of course, the list of facebook friends is different
# for each user.
def fb_friends(ctx, friends_list):
	if friends_list is None:
		logging.error('failed to retrieve Facebook friends because friends_list is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if ctx.user_id is None:
		logging.error('failed to retrieve Facebook friends because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	# TODO:
	# This is broken because we are showing too much
	#
	# We shouldn't show friends who have sent us a request,
	# whether we've denied it or not.
	logging.info('gathering suggestions from a list of %d Facebook friends', len(friends_list))

	# Generate a list of compairson conditions, with placeholders
	conditions = list()
	for i in range(0, len(friends_list)):
			conditions.append("accounts.facebook_id = %s")
	# Instantiate the friend suggestion query
	# without the condition that it should match
	# with the list of friends provided.
	friend_suggestions = """
	SELECT
		accounts.id,
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email
	FROM 
		accounts
	WHERE 
		accounts.id not in (
			SELECT blocked_accounts_id FROM blocked_accounts WHERE accounts_id=%s
			) and
		accounts.id not in (
			SELECT requestee_accounts_id FROM friend_requests WHERE requester_accounts_id=%s
			) and
		accounts.id not in (
			SELECT requester_accounts_id FROM friend_requests WHERE requestee_accounts_id=%s
			) and 
		accounts.id not in (
			SELECT friend_accounts_id FROM friends WHERE accounts_id=%s)
	"""
	# Expand the conditions list into a condition string
	condition_string = " or ".join(conditions)
	friend_suggestions = friend_suggestions + " and (" + condition_string + ");"
	# Run the query
	try:
		ctx.cur.execute(friend_suggestions, (ctx.user_id,)*4 + tuple(friends_list))
	except Exception as exc:
		logging.error('exception raised when retrieving friend suggestions for user %d, %s', ctx.user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	suggestions = []
	if len(rows):
		suggestions = [{'id':row[0], 'first':row[1], 'last':row[2], 'facebook_id':row[3], 'email':row[4]} for row in rows]
	else:
		logging.debug('no rows returned for user %d Facebook friend suggestions', ctx.user_id)
	return response.block(payload=suggestions)


def get_friends(ctx):
	if ctx.user_id is None:
		logging.error('failed to get friends ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	friends_query = """
	SELECT
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email,
		accounts.id
	FROM
		accounts, friends
	WHERE
		accounts.id = friends.friend_accounts_id and
		friends.accounts_id = %s;
	"""
	try:
		ctx.cur.execute(friends_query, (ctx.user_id,))
	except Exception as exc:
		logging.error('exception raised while trying to retrieve friends for user %d, %s', ctx.user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	friends = []
	if len(rows):
		friends = [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3], 'account_id':str(row[4])} for row in rows]
	else:
		logging.debug('no rows returned for user %d when retrieving friends list', ctx.user_id)
	return response.block(payload=friends)

def get_blocked(ctx):
	if ctx.user_id is None:
		logging.error('failed to get blocked accounts because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	blocked_query = """
	SELECT
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email
	FROM
		accounts, blocked_accounts
	WHERE
		accounts.id = blocked_accounts.blocked_accounts_id and
		blocked_accounts.accounts_id = %s
	"""
	try:
		ctx.cur.execute(blocked_query, (ctx.user_id,))
	except Exception as exc:
		logging.error('raised exception while retrieving list of blocked users for user %d', ctx.user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	blocked = []
	if len(rows):
		blocked = [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d when retrieving blocked users', ctx.user_id)
	return response.block(payload=blocked)
	
def deny(ctx, deny_id):
	deny_query = """
	UPDATE
		friend_requests
	SET
		denied=true
	WHERE
		requester_accounts_id = %s and 
		requestee_accounts_id = %s;
	"""
	try:
		ctx.cur.execute(deny_query, (deny_id, ctx.user_id))
	except Exception as exc:
		logging.error('raised an exception while %d tried denying a friend request from %d', ctx.user_id, deny_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	return response.block()

def get_denied(ctx):
	denied_query = """
	SELECT
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email
	FROM
		accounts, friend_requests
	WHERE
		accounts.id = friend_requests.requester_accounts_id and
		friend_requests.denied = true and
		friend_requests.requestee_accounts_id = %s;
	"""
	try:
		ctx.cur.execute(denied_query, (ctx.user_id,))
	except Exception as exc:
		logging.error('raised exception while retrieving list of denied users for user %d', ctx.user_id)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	denied = []
	if len(rows):
		denied = [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d when retrieving list of denied users')
	return response.block(payload=denied)

@util.single_transaction
def send_request(ctx, requestee):
	if requestee is None:
		logging.error('failed to send request because requestee is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if ctx.user_id is None:
		logging.error('failed to send request because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	requester = ctx.user_id
	if requester == requestee:
		logging.error('failed to send request, requester (%d) cannot match requestee (%d).', requester, requestee)
		return response.block(error=strings.VALUE_ERROR, code=500)
	# Check if the two accounts are friends.
	friends_query = 'SELECT count(*) FROM friends WHERE accounts_id=%s and friend_accounts_id=%s;'
	try:
		ctx.cur.execute(friends_query, (requester, requestee))
	except Exception as exc:
		return response.block(error=strings.SERVER_ERROR, code=500)
	row = ctx.cur.fetchone()
	count = int(row[0])
	if count > 0:
		return response.block(error=strings.SERVER_ERROR, code=500)
	
	# We should check first that the user has not been blocked by the requestee
	requestee_blocked_query = 'SELECT blocked_accounts_id FROM blocked_accounts WHERE accounts_id=%s;'
	try:
		ctx.cur.execute(requestee_blocked_query, (requestee,))
	except Exception as exc:
		logging.error('raised an exception while %d trying to send a friend request to %d\n%s', requester, requestee, str(exc))
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	blocked_account_ids = [row[0] for row in rows]
	if ctx.user_id in blocked_account_ids:
		logging.warning('trying to send a friend request to a user (%d) who has blocked you (%d)', requestee, ctx.user_id)
		return response.block(error=strings.VALUE_ERROR, code=500)
	# Send the request. Insert the info in the database.
	logging.debug('%d attempting to send request to %d', requester, requestee)
	insert_query = """
	INSERT INTO friend_requests
		(requester_accounts_id, requestee_accounts_id)
	VALUES
		(%s, %s);
	"""
	try:
		ctx.cur.execute(insert_query, (requester, requestee))
	except psycopg2.IntegrityError as intexc:
		if 'duplicate' in str(intexc):
			logging.info('%d sent a request to %d multiple times', requester, requestee)
			return response.block(error=strings.SERVER_ERROR, code=500)
			
		logging.warning('failed to send request because one of the accounts did not exists in the accounts table')
		return response.block(error=strings.NOT_FOUND, code=404)
	except Exception as exc:
		logging.error('raised an exception while %d trying to send a friend request to %d\n%s', requester, requestee, str(exc))
		return response.block(error=strings.SERVER_ERROR, code=500)
	logging.debug('%d sent friend request to %d', requester, requestee)
	return response.block()

@util.single_transaction	
def accept_request(ctx, requester):
	if requester is None:
		logging.error('failed tring to accept request because requester value is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	requestee = ctx.user_id
	if requestee is None:
		logging.error('failed trying to accept request because requestee value is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	# Now remove the request from the friend_requests table
	delete_query = """
	DELETE FROM
		friend_requests
	WHERE
		(requestee_accounts_id = %s and
		requester_accounts_id = %s) or
		(requestee_accounts_id = %s and
		requester_accounts_id = %s) 
	RETURNING *;
	""" # We want to delete both sides, incase one person denied the other
	try:
		ctx.cur.execute(delete_query, (requestee, requester, requester, requestee))
	except Exception as exc:
		logging.error('exception raised trying to remove friend request entry, during an accept_request')
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		return response.block(error=strings.NOT_FOUND, code=404)
	# This is actually a two step motion in-of-itself, because we add the mirror of the two.
	# For example:
	# A -> B are friends
	# B -> A are friends
	insert_query = """
	INSERT INTO friends
		(accounts_id, friend_accounts_id)
	VALUES
		(%s, %s);
	"""
	# Attempt to insert the first row.
	try:
		ctx.cur.execute(insert_query, (requestee, requester)) #Requestee first
	except psycopg2.IntegrityError as intexc:
		logging.warning('failed to accept request because requester %d was not found in accounts table')
		return response.block(error=strings.NOT_FOUND, code=404)
	except Exception as exc:
		logging.error('exception raised trying to commit friendship between %d and %d', requestee, requester)
		return response.block(error=strings.SERVER_ERROR, code=500)
	# Attempt to insert the second row.
	try:
		ctx.cur.execute(insert_query, (requester, requestee)) #Requester first
	except Exception as exc:
		logging.error('exception raised trying to commit friendship bewteen %d and %d', requestee, requester)
		return response.block(error=strings.SERVER_ERROR, code=500)
	return response.block()

def decline_request(ctx, requester):
	requestee = ctx.user_id
	if requestee is None:
		logging.error('failed to decline request because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if requester is None:
		logging.error('failed to decline request because requester is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
		
	update_query = """
	UPDATE friend_requests SET
		denied = true
	WHERE
		requestee_accounts_id=%s and
		requester_accounts_id=%s
	RETURNING *;
	"""
	try:
		ctx.cur.execute(update_query, (requestee, requester))
	except Exception as exc:
		logging.error('exception raised when %d tried to decline friend request from %d, %s', requestee, requester, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		logging.warning('trying to decline a request that does not exist')
		return response.block(error=strings.NOT_FOUND, code=404)
	return response.block()

def remove_friend(ctx, friend_user_id):
	if ctx.user_id is None:
		logging.error('failed to remove friend because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if friend_user_id is None:
		logging.error('failed to remove friend because friend_user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	delete_friend_query = """
	DELETE FROM friends WHERE
		(accounts_id=%s and friend_accounts_id=%s) or
		(accounts_id=%s and friend_accounts_id=%s)
	RETURNING *;
	"""
	try:
		ctx.cur.execute(delete_friend_query, (ctx.user_id, friend_user_id, friend_user_id, ctx.user_id))
	except Exception as exc:
		logging.error('exception raised when %d tried to remove friend %d, %s', ctx.user_id, friend_user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	if len(rows) == 0:
		return response.block(error=strings.NOT_FOUND, code=500)
	return response.block()

@util.single_transaction
def block(ctx, block_user_id):
	if block_user_id is None:
		logging.error('failed to block because block_user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)
	if ctx.user_id is None:
		logging.error('failed to block because ctx.user_id is None')
		return response.block(error=strings.VALUE_ERROR, code=500)

	# If this person is your friend,
	# they should be removed as your friend first.
	# And then continued..

	find_friend_query = """
	SELECT *
	FROM friends
	WHERE
		accounts_id=%s and
		friend_accounts_id=%s;
	"""
	try:
		ctx.cur.execute(find_friend_query, (ctx.user_id, block_user_id))
	except Exception as exc:
		logging.error('exception raised when trying to determine if user %d is friends with %d, %s', ctx.user_id, block_user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	rows = ctx.cur.fetchall()
	# If a row is returned, then we should first delete
	# the record of these two users being friends.
	# Keep in mind.
	# We need to delete the mirrored relationship.
	# A -> B
	# B -> A
	if len(rows):
		# We don't want to call the pre-defined 'remove_friend'
		# function because that will cause a premature commitment
		# of this transaction. Instead, we continue our own query
		# within this ctx.current transaction, which we control when we
		# commit. And because of the @single_transaction decorator,
		# this transaction will be committed once the scope ends.
		delete_friend_query = """
		DELETE FROM friends
		WHERE
			(accounts_id=%s and friend_accounts_id=%s) or
			(accounts_id=%s and friend_accounts_id=%s);
		"""
		try:
			ctx.cur.execute(delete_friend_query, (ctx.user_id, block_user_id, block_user_id, ctx.user_id))
		except Exception as exc:
			logging.error('exception raised when trying to delete users %d and %d, %s', ctx.user_id, block_user_id, str(exc))
			return response.block(error=strings.SERVER_ERROR, code=500)
	# We can add this user to the block table now.
	block_user_query = """
	INSERT INTO blocked_accounts
		(accounts_id, blocked_accounts_id)
	VALUES
		(%s, %s);
	"""
	try:
		ctx.cur.execute(block_user_query, (ctx.user_id, block_user_id))
	except psycopg2.IntegrityError as intexc:
		logging.warning('failed to block %d because id was not found in accounts table', block_user_id)
		return response.block(error=strings.NOT_FOUND, code=404)
	except Exception as exc:
		logging.error('exception raised when inserting blocked users %d and %d, %s', ctx.user_id, block_user_id, exc)
		return response.block(error=strings.SERVER_ERROR, code=500)
	return response.block()
