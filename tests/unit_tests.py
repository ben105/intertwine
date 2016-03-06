import unittest
import psycopg2
import intertwine
import intertwine.testdb
import os

test_dir = os.path.dirname(os.path.realpath(__file__))

TEST_DB = 'test__database'

def get_modules(cur):
	# All unit tests that should be tested.
	# First let's look at all files in the directory.
	tests = os.listdir(test_dir)
	tests.remove(__file__)
	moduleNames = map(lambda x: x.rstrip('.py'), tests)
	unittest_modules = map(__import__, moduleNames)
	for module in unittest_modules:
		if getattr(module, 'cur', None) is not None:
			module.cur = cur
	return unittest_modules
	

def suite(modules):
	"""Gather all the unit tests from the other modules.
	Build one suite, and run it altogether.
	"""
	test_suite = unittest.TestSuite()
	for module in modules:
 		test_suite.addTests(module)
 	return test_suite



if __name__ == '__main__':

	cur = intertwine.testdb.start(TEST_DB)
	modules = get_modules(cur)

	runner = unittest.TextTestRunner()
	runner.run(suite(modules))

	intertwine.testdb.stop(cur, TEST_DB)
