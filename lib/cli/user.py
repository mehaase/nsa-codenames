import app.database
import cli
from model import User

class UserCli(cli.BaseCli):
    """ A tool for managing users. """

    def _get_args(self, arg_parser):
        """ Customize arguments. """

        arg_parser.add_argument(
            'action',
            choices=('bless','demote'),
            help='Specify what action to take.'
        )

        arg_parser.add_argument(
            'user',
            help='Specify which user to perform the action on.'
        )

    def _run(self, args, config):
        """ Main entry point. """

        database_config = dict(config.items('database'))
        engine = app.database.get_engine(database_config, args.debug)
        session = app.database.get_session(engine)

        user = session.query(User) \
                      .filter(User.username.like(args.user)) \
                      .first()

        if user is None:
            self.error('User "%s" does not exist.' % args.user)

        if args.action == 'bless':
            user.is_admin = True
        elif args.action == 'demote':
            user.is_admin = False

        session.commit()

        self._logger.info('User "%s" is admin: %s' % (args.user, user.is_admin))
