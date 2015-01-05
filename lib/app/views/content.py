from datetime import datetime

from flask import g, jsonify, request
from flask.ext.classy import FlaskView
from werkzeug.exceptions import BadRequest, NotFound, Unauthorized

from app import flask_app
from app.authorization import admin_required
from app.rest import date_to_timestamp
from model import Content, User

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

        content = self._get_content_by_name(name)

        return jsonify(
            markdown=content.markdown,
            updated=date_to_timestamp(content.updated)
        )

    @admin_required
    def put(self, name):
        ''' Update a piece of Markdown content. '''

        content_json = request.get_json()

        content = self._get_content_by_name(name)
        content.markdown = content_json['markdown']
        content.updated = datetime.today()

        g.db.commit()

        return jsonify(message='Content "%s" updated.' % name)

    def _get_content_by_name(self, name):
        ''' Get a content object by name. '''

        content = g.db.query(Content) \
                      .filter(Content.name == name) \
                      .first()

        if content is None:
            raise NotFound('Content named "%s" does not exist.' % name)

        return content
