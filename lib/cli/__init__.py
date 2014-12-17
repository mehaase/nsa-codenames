import argparse

import app.config

""" Base class for CLI scripts. """
class BaseCli:

    """ Parse command line arguments. """
    def get_args(self):
        arg_parser = argparse.ArgumentParser(description=self.__class__.__doc__)

        arg_parser.add_argument(
            '--debug',
            action='store_true',
            help='Enable debug mode.'
        )

        self._get_args(arg_parser)

        return arg_parser.parse_args()

    """ The main entry point for all scripts. """
    def run(self):
        self._run(self.get_args(), app.config.get_config())

    """ Subclasses may override _get_args() to customize argument parser. """
    def _get_args(self, arg_parser):
        pass

    """ Subclasses should override _run() to do their work. """
    def _run(self, args, config):
        raise NotImplementedError()

