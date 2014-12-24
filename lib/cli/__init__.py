import argparse
from datetime import datetime
import sys

import app.config

class BaseCli:
    """ Base class for CLI scripts. """

    def get_args(self):
        """ Parse command line arguments. """

        arg_parser = argparse.ArgumentParser(description=self.__class__.__doc__)

        arg_parser.add_argument(
            '--debug',
            action='store_true',
            help='Enable debug mode.'
        )

        self._get_args(arg_parser)

        return arg_parser.parse_args()

    def error(self):
        ''' Print an error message to stderr and then quit. '''

        self.info(message, sys.stderr)
        sys.exit(1)

    def info(self, message, file_=sys.stdout):
        ''' Print an informational message to stdout (or another file). '''

        now = datetime.today().strftime('%Y-%m-%d %H:%M:%S')
        file_.write('[%s] %s\n' % (now, message))

    def run(self):
        """ The main entry point for all scripts. """

        self._run(self.get_args(), app.config.get_config())

    def _get_args(self, arg_parser):
        """
        Subclasses may override _get_args() to customize argument parser.
        """

        pass

    def _run(self, args, config):
        """ Subclasses should override _run() to do their work. """

        raise NotImplementedError()

