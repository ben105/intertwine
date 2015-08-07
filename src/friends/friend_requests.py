import logging

def single_transaction(func):
	def inner(*argv, **kwargs):
		assert(len(argv)>0)
		cursor = argv[0]
		cursor.connection.autocommit = False
		success = func(*argv, **kwargs)
		if success is not None and success == False:
			logging.error('single transaction failed, and is rolling back')
			cursor.rollback()
		else:
			logging.debug('single transaction completed')
			cursor.connection.commit()
		cursor.connection.autocommit = True
		return success
	return inner


def fb_friends(cursor, user_id,  fb_list):
	# fb_list is a list of facebook IDs of friends (who have
	# an Intertwine account.
	fb_conditions = ["facebook_id='{}'".format(fb_id) for fb_id in fb_list]
	fb_conditions_str = " or ".join(fb_conditions)
	query = """SELECT distinct
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email,
		accounts.id,
		requestee_accounts_id
	FROM 
		accounts, friend_requests, blocked_accounts
	WHERE
		friend_requests.requester_accounts_id = %s and 
		friend_requests.requestee_accounts_id = accounts.id and
		(""" + fb_conditions_str + """) and
		%s not in (SELECT blocked_accounts_id 
			   FROM blocked_accounts 
			   WHERE accounts_id=accounts.id);
	"""
	rows = []
	try:
		cursor.execute(query, (user_id, user_id))
		rows = cursor.fetchall()
	except Exception as exc:
		logging.error('exception raised searching for user %d Facebook friends\n%s', user_id, exc)
	if len(rows):
		requestee_accounts_id = row[5]
		sent = True if requestee_accounts_id else False
		return [{'account_id':row[4], 'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3], 'sent':sent} for row in rows]
	else:
		return None


def purge_blocked(cursor, user_id, blocked_user_id):
	delete_query = """
	DELETE FROM blocked_accounts
	WHERE
		accounts_id = %s and
		blocked_accounts_id = %s;
	"""
	cursor.execute(delete_query, (user_id, blocked_user_id))


# Pending Requests
#
# This query will retirive the list of friends from whom
# you have a pending request.
# It will ignore requests you've previously denied.
def get_pending_requests(cursor, user_id):
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
		cursor.execute(pending_requests_query, (user_id,))
	except Exception as exc:
		logging.error('exception raised retrieving pending requests for user %d, %s', user_id, exc)
		return None
	rows = cursor.fetchall()
	if len(rows):
		return [{'account_id':row[4], 'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d getting pending requests', user_id)
		return None


# Friend suggestions
#
# This query, as of this writing (01/07/15), will use
# this list of Facebook friends to find accounts in 
# the Intertwine database for friend suggestions.
# Of course, the list of facebook friends is different
# for each user.
def get_friend_suggestions(cusror, user_id, friends_list):

	# TODO:
	# This is broken because we are showing too much
	#
	# We shouldn't show friends who have sent us a request,
	# whether we've denied it or not.
	logging.info('gathering suggestions from a list of %d Facebook friends', len(friends_list))

	# Generate a list of compairson conditions, with placeholders
	conditions = list()
	for i in range(0, len(friends_list)):
			conditions.append("accounds.id = %s")
	# Instantiate the friend suggestion query
	# without the condition that it should match
	# with the list of friends provided.
	friend_suggestions = """
	SELECT
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email
	FROM 
		accounts, friends
	WHERE 
		  accounts.id not in (SELECT blocked_account_id FROM blocked_accounts) and
		  accounts.id not in (SELECT requestee_id FROM friend_requests) and
		  accounts.id not in (SELECT requester_id FROM friend_requests)
	"""
	# Expand the conditions list into a condition string
	condition_string = " or ".join(conditions)
	friend_suggestions = friend_suggestions + " and (" + condition_string + ");"
	# Run the query
	try:
		cursor.execute(friend_suggestions, tuple(friends_list))
	except Exception as exc:
		logging.error('exception raised when retrieving friend suggestions for user %d, %s', user_id, exc)
		return None
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d Facebook friend suggestions', user_id)
		return None


def get_friends(cursor, user_id):
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
		cursor.execute(friends_query, (user_id,))
	except Exception as exc:
		logging.error('exception raised while trying to retrieve friends for user %d, %s', user_id, exc)
		return []
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3], 'account_id':str(row[4])} for row in rows]
	else:
		logging.debug('no rows returned for user %d when retrieving friends list', user_id)
		return []

def get_blocked(cursor, user_id):
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
		cursor.execute(blocked_query, (user_id,))
	except Exception as exc:
		logging.error('raised exception while retrieving list of blocked users for user %d', user_id)
		return None
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d when retrieving blocked users', user_id)
		return None
	
def get_denied(cursor, user_id):
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
		cursor.execute(denied_query, (user_id,))
	except Exception as exc:
		logging.error('raised exception while retrieving list of denied users for user %d', user_id)
		return None
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		logging.debug('no rows returned for user %d when retrieving list of denied users')
		return None


def send_request(cursor, requester, requestee):
	logging.debug('%d attempting to send request to %d', requester, requestee)
	if not requester or not requestee:
		error_block = {
			'error':'A problem has occured on the server, please try again later.',
			'success':False
		}
		logging.error('missing ID in parameters provided to the "send_request" method')
		return error_block
	insert_query = """
	INSERT INTO friend_requests
		(requester_accounts_id, requestee_accounts_id)
	VALUES
		(%s, %s);
	"""
	try:
		cursor.execute(insert_query, (requester, requestee))
	except Exception as exc:
		logging.error('raised an exception while %d trying to send a friend request to %d', requester, requestee)
		error_block = {
			'error':'A problem has occured on the server, please try again later.',
			'success':False
		}
		return error_block
	logging.debug('%d sent friend request to %d', requester, requestee)
	success_block = {
		'success':True
	}
	return success_block

@single_transaction	
def accept_request(cursor, requestee, requester):
	# First step, add the requester as a friend
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
		cursor.execute(insert_query, (requestee, requester)) #Requestee first
	except Exception as exc:
		logging.error('exception raised trying to commit friendship between %d and %d', requestee, requester)
		return False
	# Attempt to insert the second row.
	try:
		cursor.execute(insert_query, (requester, requestee)) #Requester first
	except Exception as exc:
		logging.error('exception raised trying to commit friendship bewteen %d and %d', requestee, requester)
		return False
	# Now remove the request from the friend_requests table
	delete_query = """
	DELETE FROM
		friend_requests
	WHERE
		(requestee_accounts_id = %s and
		requester_accounts_id = %s) or
		(requestee_accounts_id = %s and
		requester_accounts_id = %s) ;
	""" # We want to delete both sides, incase one person denied the other
	try:
		cursor.execute(delete_query, (requestee, requester, requester, requestee))
	except Exception as exc:
		logging.error('exception raised trying to remove friend request entry, during an accept_request')
		return False

# def decline_request(cursor, requestee, requester):
# 	update_query = """
# 	UPDATE friend_requests
# 	SET
# 		denied = true
# 	WHERE
# 		requestee_accounts_id=%s and
# 		requester_accounts_id=%s;
# 	"""
# 	cursor.execute(update_query, (requestee, requester))

# @single_transaction
# def remove_friend(cursor, user_id, friend_user_id):
# 	delete_friend_query = """
# 	DELETE FROM friends
# 	WHERE
# 		(accounts_id=%s and friend_accounts_id=%s) or
# 		(accounts_id=%s and friend_accounts_id=%s);
# 	"""

@single_transaction
def block_user(cursor, user_id, block_user_id):
	find_friend_query = """
	SELECT *
	FROM friends
	WHERE
		accounts_id=%s and
		friend_accounts_id=%s;
	"""
	try:
		cursor.execute(find_friend_query, (user_id, block_user_id))
	except Exception as exc:
		logging.error('exception raised when trying to determine if user %d is friends with %d, %s', user_id, block_user_id, exc)
		return False
	rows = cursor.fetchall()
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
		# within this current transaction, which we control when we
		# commit. And because of the @single_transaction decorator,
		# this transaction will be committed once the scope ends.
		delete_friend_query = """
		DELETE FROM friends
		WHERE
			(accounts_id=%s and friend_accounts_id=%s) or
			(accounts_id=%s and friend_accounts_id=%s);
		"""
		try:
			cursor.execute(delete_friend_query, (user_id, block_user_id, block_user_id, user_id))
		except Exception as exc:
			logging.error('exception raised when trying to delete users %d and %d, %s', user_id, block_user_id, exc)
			return False
	# We can add this user to the block table now.
	block_user_query = """
	INSERT INTO blocked_accounts
		(accounts_id, blocked_accounts_id)
	VALUES
		(%s, %s);
	"""
	try:
		cursor.execute(block_user_query, (user_id, block_user_id))
	except Exception as exc:
		logging.error('exception raised when inserting blocked users %d and %d, %s', user_id, block_user_id, exc)
		return False