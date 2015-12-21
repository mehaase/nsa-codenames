from textwrap import dedent

import cli
from model import Base, Codename, Content, Image, Reference

import app.database

class DatabaseCli(cli.BaseCli):
    ''' A tool for initializing the database. '''

    def _create_fixture_data(self):
        ''' Create fixture data. '''

        session = app.database.get_session(self._db)

        about = Content('about')
        about.markdown = dedent('''
            ## Placeholder

            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce
            aliquam ex a sem vulputate ultrices. Integer vestibulum lacus porta
            dui euismod bibendum.
        ''')
        session.add(about)

        home = Content('home')
        home.markdown = dedent('''
            ## Placeholder

            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce
            aliquam ex a sem vulputate ultrices. Integer vestibulum lacus porta
            dui euismod bibendum.
        ''')
        session.add(home)

        session.commit()

    def _create_sample_data(self):
        ''' Create sample data. '''

        session = app.database.get_session(self._db)

        aggravated_avatar = Codename("AGGRAVATED AVATAR")
        aggravated_avatar.summary = dedent('''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed porta
            sagittis mi a faucibus.
        ''')
        aggravated_avatar.description = dedent('''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed porta
            sagittis mi a faucibus. Etiam lacinia id ex eu accumsan. Duis at
            venenatis tortor, nec ultricies enim.
        ''')
        aggravated_avatar.references.append(Reference(
            'http://yahoo.com', 'Lorem ipsum dolor sit amet.'
        ))
        aggravated_avatar.references.append(Reference(
            'http://google.com', 'Lorem ipsum dolor sit amet.'
        ))
        session.add(aggravated_avatar)

        amused_bouche = Codename("AMUSED BOUCHE")
        amused_bouche.summary = dedent('''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed porta
            sagittis mi a faucibus.
        ''')
        amused_bouche.description = dedent('''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed porta
            sagittis mi a faucibus.
        ''')
        amused_bouche.references.append(Reference(
            'http://apple.com', 'Lorem ipsum dolor sit amet.'
        ))
        session.add(amused_bouche)

        bored_boxer = Codename("BORED BOXER")
        bored_boxer.summary = dedent('''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed porta
            sagittis mi a faucibus.
        ''')
        bored_boxer.description = dedent('''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed porta
            sagittis mi a faucibus. Etiam lacinia id ex eu accumsan. Duis at
            venenatis tortor, nec ultricies enim.
        ''')
        bored_boxer.references.append(Reference(
            'http://ibm.com', 'Lorem ipsum dolor sit amet.'
        ))
        bored_boxer.references.append(Reference(
            'http://microsoft.com', 'Lorem ipsum dolor sit amet.'
        ))
        session.add(bored_boxer)

        session.commit()

    def _get_args(self, arg_parser):
        ''' Customize arguments. '''

        arg_parser.add_argument(
            'action',
            choices=('build','drop'),
            help='Specify what action to take.'
        )

        arg_parser.add_argument(
            '--debug-db',
            action='store_true',
            help='Print database queries.'
        )

        arg_parser.add_argument(
            '--sample-data',
            action='store_true',
            help='Create sample data.'
        )

    def _run(self, args, config):
        ''' Main entry point. '''

        if args.debug_db:
            # Configure database logging.
            log_level = getattr(logging, args.verbosity.upper())

            db_logger = logging.getLogger('sqlalchemy.engine')
            db_logger.setLevel(log_level)
            db_logger.addHandler(self._log_handler)

        database_config = dict(config.items('database'))
        self._db = app.database.get_engine(database_config, superuser=True)

        if args.action in ('build', 'drop'):
            self._logger.info('Dropping database tables.')
            self._drop_all()

        if args.action == 'build':
            self.info('Creating database tables.')
            Base.metadata.create_all(self._db)

            self.info('Creating fixture data.')
            self._create_fixture_data()

        if args.sample_data:
            self.info('Creating sample data.')
            self._create_sample_data()
