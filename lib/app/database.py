import sqlalchemy
from sqlalchemy.orm import sessionmaker

_engine = None
_sessionmaker = None


def get_engine(config, super_user=False):
    '''
    Get a SQLAlchemy engine from a configuration object.

    If ``super_user`` is True, then connect as super user -- typically reserved
    for issuing DDL statements.
    '''

    global _engine

    if _engine is None:
        if super_user:
            connect_string = 'mysql+pymysql://%(super_username)s' \
                             ':%(super_password)s@%(host)s/%(database)s?'
        else:
            connect_string = 'mysql+pymysql://%(username)s:%(password)s' \
                             '@%(host)s/%(database)s'

        _engine = sqlalchemy.create_engine(
            connect_string % config,
            pool_recycle=3600
        )

    return _engine


def get_session(engine):
    ''' Get a SQLAlchemy session. '''

    global _sessionmaker

    if _sessionmaker is None:
        _sessionmaker = sessionmaker()

    return _sessionmaker(bind=engine)
