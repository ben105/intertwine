import logging
import optparse

levelMap = {
	'debug':logging.DEBUG,
	'info':logging.INFO,
	'warning':logging.WARNING,
	'error':logging.ERROR,
	'critical':logging.CRITICAL
}

LEVEL = None

parser = optparse.OptionParser()
parser.add_option('-l', '--log_level',
	dest='logging_level',
	help='logging level')

options, args = parser.parse_args()
if options.logging_level:
	LEVEL = levelMap.get(options.logging_level.lower())

if LEVEL is None:
	LEVEL = logging.ERROR


def EnableLogging():
	path = '/var/log/intertwine/intertwine.log'
	logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s: %(message)s', 
		filemode='a',
		filename=path, 
			level=LEVEL)
