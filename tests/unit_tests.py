import unittest
import psycopg2
import intertwine

TEST_DB = 'test__database'


def distribute_cur(cur):
	# All unit tests that should be tested.
	# IMPORTANT: Add additional modules here, when adding
	# unit tests.
	unittest_modules = [
		intertwine.accounts_tests,
		intertwine.activity_tests,
		intertwine.events_tests,
		intertwine.friends_tests,
		intertwine.registration_tests,
		intertwine.search_tests
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
	distribute_cur(cur)

	runner = unittest.TextTestRunner()
	runner.run(suite())

	intertwine.testdb.stop(TEST_DB)
