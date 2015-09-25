def new_activity(friend, activity):
	return '{} added you to an activity, {}'.format(friend, activity)

def activity_cancelled(friend, activity):
	return '{} has cancelled {}'.format(friend, activity)

def time_changed(friend, activity, time):
	return '{} changed the time of {} to {}'.format(friend, activity, time)

def location_changed(friend, activity, location):
	return '{} changed the location of {} to {}'.format(friend, activity, location)

def activity_completed(activity):
	return '{} has been completed!'

def friend_request(friend):
	return '{} sent you a twine request'.format(friend)

def request_accepted(friend):
	return '{} accepted your twine request'.format(friend)

def liked_activity(friend, activity):
	return '{} liked your activity, {}'.format(friend, activity)

def comment_activity(friend, activity, comment):
	return '{} commented on {}: {}'.format(friend, activity, comment)

def photo_uploaded(friend, activity):
	return '{} uploaded a photo to {}'.format(friend, activity)
