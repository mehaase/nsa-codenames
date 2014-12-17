import app
import cli

""" A tool for running a development server. """
class RunServer(cli.BaseCli):

    """ Customize arguments. """
    def _get_args(self, arg_parser):

        arg_parser.add_argument(
            '--ip',
            default='127.0.0.1',
            help='Specify an IP address to bind to. (Defaults to loopback.)'
        )

    """ Main entry point. """
    def _run(self, args, config):

        flask_app = app.bootstrap()
        flask_app.run(host=args.ip, debug=args.debug)
