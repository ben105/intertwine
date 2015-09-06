import unittest
import psycopg2
import intertwine
import intertwine.testdb
import os

test_dir = os.path.dirname(os.path.realpath(__file__))

TEST_DB = 'test__database'

def distribute_cur(cur):
	# All unit tests that should be tested.
	# First let's look at all files in the directory.
	tests = os.listdir(test_dir)
	tests.remove(__file__)
	tests = map(lambda x: x.strip('.py'), tests)
	print tests
	unittest_modules = [
		intertwine.accounts_tests,
		intertwine.activity_tests,
		intertwine.events_tests,
		intertwine.friends_tests,
		intertwine.registration_tests,
		intertwine.search_tests
	]
	for module in unittest_modules:
		if getattr(module, 'cur', None) is not None:
			module.cur = cur

def suite():
    """Gather all the unit tests from the other modules.
    Build one suite, and run it altogether.
    """
    test_suite = unittest.TestSuite()
    # test_suite.addTest(unittest.makeSuite(ConfigTestCase))
    return test_suite



if __name__ == '__main__':

	cur = intertwine.testdb.start(TEST_DB)
	distribute_cur(cur)

	runner = unittest.TextTestRunner()
	runner.run(suite())

	intertwine.testdb.stop(TEST_DB)
