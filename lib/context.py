class SecurityContext(object):
	def __init__(self, request, cur, user_id, session_id):
		self.request = request
		self.cur = cur
		self.user_id = user_id
		self.session_id = session_id
		self.first = None
		self.last = None
