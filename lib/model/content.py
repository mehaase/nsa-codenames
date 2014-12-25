from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String, Text
from sqlalchemy.orm import relationship, backref

from model import Base
from model.image import Image
from model.reference import Reference

class Content(Base):
    ''' Data model for a codename. '''

    __tablename__ = 'content'

    id = Column(Integer, primary_key=True)
    name = Column(String(255), unique=True)
    markdown = Column(Text)
    updated = Column(DateTime)

    def __init__(self, name):
        ''' Constructor. '''

        self.name = name
        self.markdown = ''
        self.updated = datetime.today()
