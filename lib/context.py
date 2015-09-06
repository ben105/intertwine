class SecurityContext(object):
	def __init__(self, request, cur):
		self.user_id = int(request.headers.get('user_id'))
		self.session_id = request.headers.get('token_key')
		self.first = request.headers.get('first')
		self.last = request.headers.get('last')
		print('first name: %s' % self.first)
		print('last name: %s' % self.last)
		self.request = request
		self.cur = cur
