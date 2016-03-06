"""This module will create a temporary file structure
such that the imports work on the development code and
not on the production code, but the import statements 
look the same.
"""

import os
import sys
import shutil

cwd = os.path.dirname(os.path.realpath(__file__))
root = os.path.join(cwd, '../')

# We have to first remove a tmp directory if it exists.
tmp = os.path.join(root, 'tmp')
if os.path.exists(tmp):
	shutil.rmtree(tmp)

# Create a temporary directory where the virtual paths will
# be set up.
intertwine = os.path.join(root, '../intertwine')
tmp_intertwine = os.path.join(tmp, 'intertwine')
os.makedirs(tmp_intertwine)
f = open(os.path.join(tmp_intertwine, '__init__.py'), 'w')
f.close()

accounts = os.path.join(intertwine, 'src', 'accounts') 
tmp_accounts = os.path.join(tmp_intertwine, 'accounts')
shutil.copytree(accounts, tmp_accounts) 
f = open(os.path.join(tmp_accounts, '__init__.py'), 'w')
f.close()

activity = os.path.join(intertwine, 'src', 'activity') 
tmp_activity = os.path.join(tmp_intertwine, 'activity')
shutil.copytree(activity, tmp_activity)
f = open(os.path.join(tmp_activity, '__init__.py'), 'w')
f.close()

friends = os.path.join(intertwine, 'src', 'friends') 
tmp_friends = os.path.join(tmp_intertwine, 'friends')
shutil.copytree(friends, tmp_friends)
f = open(os.path.join(tmp_friends, '__init__.py'), 'w')
f.close()

extra = ['db', 'lib']
for module in extra:
	dirname = os.path.join(intertwine, module)
	files = os.listdir(dirname)
	for aFile in files:
		src = os.path.join(dirname, aFile)
		dst = os.path.join(tmp_intertwine, aFile)
		shutil.copy(src, dst)

# Now we need to make a __init__.py file in each directory.
for (dirpath, dirnames, filenames) in os.walk(tmp_intertwine):
	init = os.path.join(dirpath, '__init__.py')
	f = open(init, 'w')
	f.close()	

sys.path.insert(0, tmp)
