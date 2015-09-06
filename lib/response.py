"""Response blocks are dictionaries with 
information regarding the status and success
of the request.
"""
from datetime import datetime

def block(payload=None, error=None, code=200):
	"""Constructs the response block.

	Keyword Arguments:
		payload - the optional sub block (i.e 
				  session keys)
		error	- the error msg to be sent back

	Returns:
		Python dictionary that represents the
		JSON block that will be returned as the
		response to a request.
	"""
	if payload is None:
		payload = {}

	# Check that the provided payload is a string type.
	if type(payload) is not dict and type(payload) is not list:
		raise ValueError('expecting payload to be type dict/list, but got type {}'.format(type(payload)))
	if error is not None and type(error) is not str:
		raise ValueError('expecting error to be type str, but got type {}'.format(type(error)))
	if type(code) is not int:
		raise ValueError('expecting code to be type int, but got type {}'.format(type(code)))

	success = error is None
	
	return {
		'success' : success, 
		'error' : error,
		'payload' : payload,
		'status_code' : code,
		'date' : str(datetime.now())
	}

# Some default response blocks for testings.
value_error_resp = block(payload=None,
					error='invalid argument provided',
					code=412)
