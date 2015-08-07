def full_compare(dict1, dict2):
	keys1 = dict1.keys()
	keys2 = dict2.keys()
	
	# We can quickly determine the match,
	# by comparing key counts.
	if len(keys1) != len(keys2):
		return False

	for key in keys1:
		# Make sure both dictionaries have this key.
		if not key in keys2:
			return False
		# Check that the key values are the same.
		if dict1[key] != dict2[key]:
			return False
