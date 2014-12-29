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
            ## Motivation

            This site was inspired by the colorful codenames used for various
            NSA programs. The codenames evoke vivid imagery, and the they are
            perfectly suited for vivid, crowd-sourced illustrations.

            Our motive is to provide a comprehensive and useful database for
            American taxpayers to understand and analyze the intelligence
            programs that they pay for. In order to open this information up as
            much as possible, this site also features an API that enables
            programmatic access to our curated dataset.

            We place equal emphasis on whimsy and practicality; amusement and
            information. As you browse this site, we hope you'll laugh and
            cringe at alternating moments.

            ## Under The Hood

            This site is built as a single page application (SPA) with
            [Angular Dart](https://angulardart.org/)
            using a [Bootwatch theme](http://bootswatch.com/journal/).
            This SPA supports deep links and
            [search engine spiders](https://developers.google.com/webmasters/ajax-crawling/docs/getting-started).
            The server side is written in Python using
            [the Flask microframework](http://flask.pocoo.org/).
        ''')
        session.add(about)

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
        aggravated_avatar.images.append(Image(
            '/static/img/angry-neighbor.png',
            '/static/img/angry-neighbor-thumb.png'
        ))
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
        amused_bouche.images.append(Image(
            '/static/img/angry-neighbor.png',
            '/static/img/angry-neighbor-thumb.png'
        ))
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
        bored_boxer.images.append(Image(
            '/static/img/angry-neighbor.png',
            '/static/img/angry-neighbor-thumb.png'
        ))
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
            choices=('build',),
            help='Specify what action to take.'
        )

        arg_parser.add_argument(
            '--sample-data',
            action='store_true',
            help='Create sample data.'
        )

    def _run(self, args, config):
        ''' Main entry point. '''

        database_config = dict(config.items('database'))
        self._db = app.database.get_engine(database_config, args.debug)

        self.info('Dropping existing database tables.')
        Base.metadata.drop_all(self._db)

        self.info('Creating database tables.')
        Base.metadata.create_all(self._db)

        self.info('Creating fixture data.')
        self._create_fixture_data()

        if args.sample_data:
            self.info('Creating sample data.')
            self._create_sample_data()
