import json
import logging
from functools import wraps

from intertwine import context


def json_encode(func):
	"""Take the function argument and return an identical
	function that will return a JSON string of the Python
	dictionary instead.
	"""
	@wraps(func)
	def inner(*argv, **kwargs):
		return json.dumps(func(*argv, **kwargs))

	return inner

def single_transaction(func):
	"""Given the context argument as first parameter in
	the function, turn off autocommit and allow function
	to run as a single transaction.
	"""
	@wraps(func)
	def inner(*argv, **kwargs):

		# Grab the original commit value from the context,
		# if it exists.
		ctx = kwargs.get('ctx')
		if ctx is None:
			for arg in argv:
				if type(arg) is context.SecurityContext:
					ctx = arg
		elif not isinstance(ctx, context.SecurityContext):
			raise ValueError('single transaction decorator requires a parameter to be an Intertwine security context')
		
		if ctx is None:
			raise ValueError('single transaction decorator requires a parameter to be an Intertwine security context')

		commit_value = ctx.cur.connection.autocommit
		# Set it to false.
		ctx.cur.connection.autocommit = False

		resp = func(*argv, **kwargs)
		success = False
		if isinstance(resp, bool):
			success = resp
		elif resp is None:
			success = True
		elif isinstance(resp, dict) and resp.get('error') is None:
			success = True

		if success:
			logging.debug('single transaction completed')
			ctx.cur.connection.commit()
		else:
			logging.error('single transaction failed, and is rolling back')
			ctx.cur.connection.rollback()

		# Return the commit value to original value.
		ctx.cur.connection.autocommit = commit_value
		return resp
	return inner

