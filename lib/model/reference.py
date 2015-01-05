from sqlalchemy import Column, ForeignKey, Integer, String

from model import Base

class Reference(Base):
    '''
    Data model for a codename reference.
    '''

    __tablename__ = 'reference'

    id = Column(Integer, primary_key=True)
    url = Column(String(255))
    annotation = Column(String(255))

    codename_id = Column(
        Integer,
        ForeignKey('codename.id', name='fk_reference_codename_id')
    )

    def __init__(self, url, annotation):
        ''' Constructor. '''

        self.url = url
        self.annotation = annotation
