from textwrap import dedent

from sqlalchemy.engine import reflection
from sqlalchemy.schema import DropConstraint, DropTable, ForeignKeyConstraint, \
                              MetaData, Table

import app.database
import cli
from model import Base, Codename, Content, Image, Reference


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

    def _drop_all(self):
        '''
        Drop database tables, foreign keys, etc.

        Unlike SQL Alchemy's built-in drop_all() method, this one shouldn't
        punk out if the Python schema doesn't match the actual database schema
        (a common scenario while developing).

        See: https://bitbucket.org/zzzeek/sqlalchemy/wiki/UsageRecipes/DropEverything
        '''

        tables = list()
        all_fks = list()
        metadata = MetaData()
        inspector = reflection.Inspector.from_engine(self._db)

        for table_name in inspector.get_table_names():
            fks = list()

            for fk in inspector.get_foreign_keys(table_name):
                if not fk['name']:
                    continue
                fks.append(ForeignKeyConstraint((),(),name=fk['name']))

            tables.append(Table(table_name, metadata, *fks))
            all_fks.extend(fks)

        for fk in all_fks:
            try:
                self._db.execute(DropConstraint(fk))
            except Exception as e:
                self._logger.warn('Not able to drop FK "%s".' % fk.name)
                self._logger.debug(str(e))

        for table in tables:
            try:
                self._db.execute(DropTable(table))
            except Exception as e:
                self._logger.warn('Not able to drop table "%s".' % table.name)
                self._logger.debug(str(e))

        self._session.commit()

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
        self._db = app.database.get_engine(database_config, super_user=True)
        self._session = app.database.get_session(self._db)

        if args.action in ('build', 'drop'):
            self._logger.info('Dropping database tables.')
            self._drop_all()

        if args.action == 'build':
            self._logger.info('Creating database tables.')
            Base.metadata.create_all(self._db)

            self._logger.info('Creating fixture data.')
            self._create_fixture_data()

        if args.sample_data:
            self._logger.info('Creating sample data.')
            self._create_sample_data()
