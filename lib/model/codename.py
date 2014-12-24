from datetime import datetime

from slugify import slugify
from sqlalchemy import Column, DateTime, Integer, String, Text
from sqlalchemy.orm import relationship, backref

from model import Base
from model.image import Image
from model.reference import Reference

class Codename(Base):
    ''' Data model for a codename. '''

    __tablename__ = 'codename'

    id = Column(Integer, primary_key=True)
    name = Column(String(255), unique=True)
    slug = Column(String(255), unique=True)
    description = Column(Text)
    added = Column(DateTime)
    updated = Column(DateTime)

    references = relationship('Reference')
    images = relationship('Image')

    def __init__(self, name):
        ''' Constructor. '''

        self.name = name
        self.slug = slugify(name)
        self.added = datetime.today()
        self.updated = datetime.today()
