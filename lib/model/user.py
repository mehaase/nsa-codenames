from datetime import datetime

from sqlalchemy import Boolean, Column, Enum, Integer, \
                       String, Text, UniqueConstraint

from model import Base

class User(Base):
    ''' Data model for a user. '''

    __tablename__ = 'user'

    id = Column(Integer, primary_key=True)
    username = Column(String(255), unique=True)
    image_url = Column(Text)
    is_admin = Column(Boolean)
    can_change_username = Column(Boolean)

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
        self.can_change_username = True
