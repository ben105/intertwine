# Pending Requests
#
# This query will retirive the list of friends from whom
# you have a pending request.
# It will ignore requests you've previously denied.
def get_pending_requests(cursor):
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
		friend_requests.requester = accounts.id and
		friend_requests.requestee = %s;
	"""
	# Run the query
	cursor.execute(pending_requests_query, user_id)
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
	print "Building query"
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
		return None

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
		accounts, friends
	WHERE
		accounts.id = friends.friend_accounts_id and
		friends.denied = true and
		friends.accounts_id = %s;
	"""
	cursor.execute(denied_query, (user_id,))
	rows = cursor.fetchall()
	if len(rows):
		return [{'first':row[0], 'last':row[1], 'facebook_id':row[2], 'email':row[3]} for row in rows]
	else:
		return None


