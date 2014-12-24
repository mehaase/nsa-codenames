import sqlalchemy
from sqlalchemy.orm import sessionmaker

_engine = None
_sessionmaker = None

def get_engine(config, debug=False):
    ''' Get a SQLAlchemy engine from a configuration object. '''

    global _engine

    if _engine is None:
        connect_string = 'mysql+pymysql://%(username)s:%(password)s@' \
                         '%(host)s/%(schema)s'

        _engine = sqlalchemy.create_engine(connect_string % config, echo=debug)
        _sessionmaker = sessionmaker(bind=_engine)

    return _engine

def get_session(engine):
    ''' Get a SQLAlchemy session. '''

    global _sessionmaker

    if _sessionmaker is None:
        _sessionmaker = sessionmaker()

    return _sessionmaker(bind=engine)
