
def single_transaction(func):
	def inner(*argv, **kwargs):
		assert(len(argv)>0)
		cursor = argv[0]
		cursor.connection.autocommit = False
		result = func(*argv, **kwargs)
		cursor.connection.commit()
		cursor.connection.autocommit = True
		return result
	return inner



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
		accounts.email
	FROM 
		accounts, friend_requests
	WHERE
		friend_requests.denied = false and
		friend_requests.requester_accounts_id = accounts.id and
		friend_requests.requestee_accounts_id = %s;
	"""
	# Run the query
	cursor.execute(pending_requests_query, (user_id,))
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		return None


# Friend suggestions
#
# This query, as of this writing (01/07/15), will use
# this list of Facebook friends to find accounts in 
# the Intertwine database for friend suggestions.
# Of course, the list of facebook friends is different
# for each user.
def get_friend_suggestions(cusror, user_id, friends_list):

	# This is broken because we are showing too much
	#
	# We shouldn't show friends who have sent us a request,
	# whether we've denied it or not.

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
	cursor.execute(friend_suggestions, tuple(friends_list))
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		return None


def get_friends(cursor, user_id):
	print "Building query for account {}".format(user_id)
	friends_query = """
	SELECT
		accounts.first,
		accounts.last,
		accounts.facebook_id,
		accounts.email
	FROM
		accounts, friends
	WHERE
		accounts.id = friends.friend_accounts_id and
		friends.accounts_id = %s;
	"""
	print "Executing query"
	cursor.execute(friends_query, (user_id,))
	print "Retrieving results"
	rows = cursor.fetchall()
	if len(rows):
		print "Found results"
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		print "Found nothing"
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
	cursor.execute(blocked_query, (user_id,))
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
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
	cursor.execute(denied_query, (user_id,))
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		return None


def send_request(cursor, requester, requestee):
	insert_query = """
	INSERT INTO friend_requests
		(requester_accounts_id, requestee_accounts_id)
	VALUES
		(%s, %s);
	"""
	cursor.execute(insert_query, (requester, requestee))

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
	cursor.execute(insert_query, (requestee, requester)) #Requestee first
	cursor.execute(insert_query, (requester, requestee)) #Requester first
	# Now remove the request from the friend_requests table
	delete_query = """
	DELETE FROM
		friend_requests
	WHERE
		requestee_accounts_id = %s and
		requester_accounts_id = %s;
	"""
	cursor.execute(delete_query, (requestee, requester))


def deny_request(cursor, requestee, requester):
	update_query = """
	UPDATE friend_requests
	SET
		denied = true
	WHERE
		requestee_accounts_id=%s and
		requester_accounts_id=%s;
	"""
	cursor.execute(update_query, (requestee, requester))

@single_transaction
def remove_friend(cursor, user_id, friend_user_id):
	delete_friend_query = """
	DELETE FROM friends
	WHERE
		(accounts_id=%s and friend_accounts_id=%s) or
		(accounts_id=%s and friend_accounts_id=%s);
	"""

	

@single_transaction
def block_user(cursor, user_id, block_user_id):
	find_friend_query = """
	SELECT *
	FROM friends
	WHERE
		accounts_id=%s and
		friend_accounts_id=%s;
	"""
	cursor.execute(find_friend_query, (user_id, block_user_id))
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
		cursor.execute(delete_friend_query, (user_id, block_user_id, block_user_id, user_id))
	# We can add this user to the block table now.
	block_user_query = """
	INSERT INTO blocked_accounts
		(accounts_id, blocked_accounts_id)
	VALUES
		(%s, %s);
	"""
	cursor.execute(block_user_query, (user_id, block_user_id))
