from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Enum, Integer, \
                       String, Text, UniqueConstraint

from model import Base

class User(Base):
    ''' Data model for a user. '''

    __tablename__ = 'user'

    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True)
    image_url = Column(Text)
    is_admin = Column(Boolean)
    added = Column(DateTime)

    OAUTH_PROVIDERS = ['twitter']

    oauth_provider = Column(Enum(*OAUTH_PROVIDERS))
    oauth_user_id = Column(String(255))
    oauth_token = Column(String(255))
    oauth_secret = Column(String(255))

    unique_identity_constraint = UniqueConstraint(
        'oauth_provider',
        'oauth_user_id',
        name='uk_identity'
    )

    def __init__(self, username):
        ''' Constructor. '''

        self.username = username
        self.image_url = '/static/img/default-user.png'
        self.is_admin = False
        self.added = datetime.now()
