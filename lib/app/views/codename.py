from flask import g
from flask.ext.classy import FlaskView

from app import flask_app
from app.rest import dictify, json, not_found
from model import Codename

EXPOSED_FIELDS = [
    'name',
    'slug',
    'description',
    'added',
    'updated',
]

class CodenameView(FlaskView):
    ''' CRUD for codenames. '''

    def index(self):
        ''' List codenames in alphabetical order, grouped by first letter. '''

    def get(self, slug):
        ''' Get a specific codename. '''

        codename_obj = g.db.query(Codename).filter(Codename.slug == slug).one()

        if codename_obj is None:
            return not_found()

        codename = dictify(codename_obj, EXPOSED_FIELDS)
        codename['images'] = list()
        codename['references'] = list()

        for image in codename_obj.images:
            codename['images'].append({
                'url': image.path,
                'thumbUrl': image.thumbPath,
            })

        for reference in codename_obj.references:
            codename['references'].append(
                dictify(reference, ['url', 'annotation'])
            )

        return json(codename)

    def put(self, slug):
        ''' Update a codename. '''

    def delete(self, slug):
        ''' Delete a codename. '''
