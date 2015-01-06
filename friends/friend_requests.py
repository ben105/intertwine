"""
SELECT
	accounts.first,
	accounts.last,
	accounts.facebook_id,
	accounts.email
FROM 
	accounts, friends
WHERE
	friends.requester = accounts.id and
	friends.requestee = %s
"""