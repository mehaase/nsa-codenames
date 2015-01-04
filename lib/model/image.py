from sqlalchemy import Column, ForeignKey, Integer, String

from model import Base

class Image(Base):
    '''
    Data model for a codename image.
    '''

    __tablename__ = 'image'

    id = Column(Integer, primary_key=True)
    path = Column(String(255))
    thumb_path = Column(String(255))

    codename_id = Column(Integer, ForeignKey('codename.id'))

    def __init__(self, path, thumb_path):
        ''' Constructor. '''

        self.path = path
        self.thumb_path = thumb_path
