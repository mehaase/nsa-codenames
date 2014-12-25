from datetime import datetime

from flask import g, request
from flask.ext.classy import FlaskView

from app import flask_app
from app.rest import date_to_timestamp, json, not_found, success
from model import Content

class ContentView(FlaskView):
    '''
    API for Markdown content.

    This API allows for getting and updating content but does not permit
    creating new content, because content is hardwired into templates by name.
    There's no point in creating new content if it isn't already hardwired
    into a template.
    '''

    def get(self, name):
        ''' Get a piece of Markdown content. '''

        content = g.db.query(Content).filter(Content.name == name).first()

        if content is None:
            return not_found()

        content_json = {
            'markdown': content.markdown,
            'updated': date_to_timestamp(content.updated),
        }

        return json(content_json)

    def put(self, name):
        ''' Update a piece of Markdown content. '''

        content = g.db.query(Content).filter(Content.name == name).first()

        if content is None:
            return not_found()

        content_json = request.get_json()

        content.markdown = content_json['markdown']
        content.updated = datetime.today()

        g.db.commit()

        return success('Content "%s" updated.' % name)


