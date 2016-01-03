import hashlib
import os

from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Table
from sqlalchemy.orm import relationship

import app.config
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


THUMB_WIDTH = 144
THUMB_HEIGHT = 80


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

    mime = Column(String(255))

    def __init__(self, image, contributor):
        '''
        Constructor.

        This takes a Pillow `image` and a user `contributor`. It saves the
        image to the data directory and generates a thumbnail (also saved to
        the data directory).
        '''

        # Save the file (if not already present).
        data_dir = app.config.get_path('data')
        hash_ = hashlib.sha1(image.tobytes()).hexdigest()
        image_dir = os.path.join(data_dir, hash_[0], hash_[1])
        image_path = os.path.join(image_dir, hash_[2:])
        image_rel_path = os.path.join(hash_[0], hash_[1], hash_[2:])

        if not os.path.exists(image_path):
            os.makedirs(image_dir, exist_ok=True)
            image.save(image_path, format=image.format)

        # Create and save a thumbnail (if not already present).
        thumb = image.thumbnail((THUMB_WIDTH, THUMB_HEIGHT))
        thumb_hash = hashlib.sha1(image.tobytes()).hexdigest()
        thumb_dir = os.path.join(data_dir, thumb_hash[0], thumb_hash[1])
        thumb_path = os.path.join(thumb_dir, thumb_hash[2:])
        thumb_rel_path = os.path.join(thumb_hash[0], thumb_hash[1], thumb_hash[2:])

        if not os.path.exists(thumb_path):
            os.makedirs(thumb_dir, exist_ok=True)
            image.save(thumb_path, format=image.format)

        self.path = image_rel_path
        self.thumb_path = thumb_rel_path
        self.mime = 'image/jpeg' if image.format == 'JPEG' else 'image/png'
        self.contributor = contributor
        self.votes = 0
        self.approved = False
