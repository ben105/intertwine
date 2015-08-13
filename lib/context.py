class SecurityContext(object):
	def __init__(self, request, cur):
		self.user_id = int(request.headers.get('user_id'))
		self.session_id = request.headers.get('session_id')
		self.first = request.headers.get('first')
		self.last = request.headers.get('last')
		self.request = request
		self.cur = cur
