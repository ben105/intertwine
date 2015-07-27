import unittest
import psycopg2
import intertwine.testdb

import intertwine.accounts.unit_tests
import intertwine.activity.unit_tests
import intertwine.events.unit_tests
import intertwine.friends.unit_tests
import intertwine.registration.unit_tests
import intertwine.search.unit_tests

TEST_DB = 'test__database'


def distribute_cursor(cur):
	# All unit tests that should be tested.
	# IMPORTANT: Add additional modules here, when adding
	# unit tests.
	unittest_modules = [
		intertwine.accounts.unit_tests,
		intertwine.activity.unit_tests,
		intertwine.events.unit_tests,
		intertwine.friends.unit_tests,
		intertwine.registration.unit_tests,
		intertwine.search.unit_tests
	]
	for module in unittest_modules:
		if getattr(module, 'cursor', None) is not None:
			module.cursor(cur)

def suite():
    """Gather all the unit tests from the other modules.
    Build one suite, and run it altogether.
    """
    test_suite = unittest.TestSuite()
    # test_suite.addTest(unittest.makeSuite(ConfigTestCase))
    return test_suite



if __name__ == '__main__':

	cur = intertwine.testdb.start(TEST_DB)
	distribute_cursor(cur)

	runner = unittest.TextTestRunner()
	runner.run(suite())

	intertwine.testdb.stop(TEST_DB)
