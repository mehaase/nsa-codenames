from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Table
from sqlalchemy.orm import relationship

from model import Base

image_join_user = Table(
    'image_join_user',
    Base.metadata,
    Column(
        'image_id',
        Integer,
        ForeignKey('image.id', name='fk_image_join_user_image_id'),
        primary_key=True
    ),
    Column(
        'user_id',
        Integer,
        ForeignKey('user.id', name='fk_image_join_user_user_id'),
        primary_key=True
    )
)

class Image(Base):
    '''
    Data model for a codename image.
    '''

    __tablename__ = 'image'

    id = Column(Integer, primary_key=True)
    path = Column(String(255))
    thumb_path = Column(String(255))
    votes = Column(Integer)
    approved = Column(Boolean)

    voters = relationship(
        'User',
        secondary=image_join_user,
        backref='voted_images'
    )

    codename_id = Column(
        Integer,
        ForeignKey('codename.id', name='fk_image_codename_id')
    )

    contributor_id = Column(
        Integer,
        ForeignKey('user.id', name='fk_image_contributor_id')
    )

    contributor = relationship(
        'User',
        backref='contributed_images'
    )

    def __init__(self, path, thumb_path, contributor):
        ''' Constructor. '''

        self.path = path
        self.thumb_path = thumb_path
        self.contributor = contributor
        self.votes = 0
        self.approved = False
