class SecurityContext(object):
	def __init__(self, request, cur):
		user_id = request.headers.get('user_id')
		if user_id is not None and isinstance(user_id, int):
			self.user_id = int(user_id)
		else:
			self.user_id = None
		self.session_id = request.headers.get('token_key')
		self.first = request.headers.get('first')
		self.last = request.headers.get('last')
		self.request = request
		self.cur = cur
