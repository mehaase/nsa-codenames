from datetime import datetime

from flask import g, request
from flask.ext.classy import FlaskView, route
from sqlalchemy.exc import IntegrityError

from app import flask_app
from app.rest import date_to_timestamp, error, json, not_found, success, url_for
from model import Codename, Image, Reference

DEFAULT_IMAGE_URL = '/static/img/angry-neighbor.png'
DEFAULT_THUMB_URL = '/static/img/angry-neighbor-thumb.png'

class CodenameView(FlaskView):
    ''' API for Codename and related models. '''

    def delete(self, slug):
        ''' Delete a codename. '''

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if codename is None:
            return not_found()

        g.db.delete(codename)
        g.db.commit()

        return success('Codename "%s" deleted.' % codename.name)

    @route('/<slug>/references/<int:reference_id>', methods=('DELETE',))
    def delete_reference(self, slug, reference_id):
        ''' Delete a reference. '''

        reference = g.db.query(Reference) \
                        .filter(Reference.id == reference_id) \
                        .first()

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if reference is None or codename is None or \
            reference.codename is not codename:

            return not_found()

        codename.updated = datetime.today()
        g.db.delete(reference)
        g.db.commit()

        message = 'Reference %d deleted from codename "%s".'
        return success(message % (reference.id, codename.name))

    @route('/<slug>/images/<int:image_id>', methods=('DELETE',))
    def delete_image(self, slug, image_id):
        ''' Delete an image from a codename. '''

        image = g.db.query(Image).filter(Image.id == image_id).first()
        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if image is None or codename is None or image.codename is not codename:
            return not_found()

        codename.updated = datetime.today()
        g.db.delete(image)
        g.db.commit()

        message = 'Image %d deleted from codename "%s".'
        return success(message % (image.id, codename.name))

    def get(self, slug):
        ''' Get a codename. '''

        codename = g.db.query(Codename) \
                       .filter(Codename.slug == slug) \
                       .first()

        if codename is None:
            return not_found()

        codename_json = {
            'name': codename.name,
            'summary': codename.summary,
            'description': codename.description,
            'added': date_to_timestamp(codename.added),
            'updated': date_to_timestamp(codename.updated),
            'images': list(),
            'references': list(),
        }

        for image in codename.images:
            codename_json['images'].append({
                'url': url_for(
                    'CodenameView:get_image',
                    slug=codename.slug,
                    image_id=image.id
                ),
                'thumbUrl': url_for(
                    'CodenameView:get_thumb',
                    slug=codename.slug,
                    image_id=image.id
                ),
            })

        for reference in codename.references:
            codename_json['references'].append({
                'externalUrl': reference.url,
                'annotation': reference.annotation,
                'url': url_for(
                    'CodenameView:get_reference',
                    slug=codename.slug,
                    reference_id=reference.id
                )
            })

        return json(codename_json)

    @route('/<slug>/images/<int:image_id>')
    def get_image(self, slug, image_id):
        ''' Send an image. '''

        image = g.db.query(Image).filter(Image.id == image_id).first()
        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if image is None or codename is None or image.codename is not codename:
            return not_found()

        # Strip '/static' prefix:
        return flask_app.send_static_file(image.path[8:])

    @route('/<slug>/references/<int:reference_id>')
    def get_reference(self, slug, reference_id):
        ''' Get a reference. '''

        reference = g.db.query(Reference) \
                        .filter(Reference.id == reference_id) \
                        .first()

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if reference is None or codename is None or \
            reference.codename is not codename:

            return not_found()

        reference_json = {
            'url': reference.url,
            'annotation': reference.annotation,
        }

        return json(reference_json)

    @route('/<slug>/images/<int:image_id>/thumbnail')
    def get_thumb(self, slug, image_id):
        ''' Send a thumbnail. '''

        image = g.db.query(Image).filter(Image.id == image_id).first()
        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if image is None or codename is None or image.codename is not codename:
            return not_found()

        # Strip '/static' prefix:
        return flask_app.send_static_file(image.thumbPath[8:])

    @route('/index')
    def index(self):
        ''' List codenames in alphabetical order. '''

        codenames = g.db.query(Codename).order_by(Codename.name)
        codenames_json = list()

        for codename in codenames:
            codename_json = {
                'name': codename.name,
                'summary': codename.summary,
                'url': url_for('CodenameView:get', slug=codename.slug)
            }

            if len(codename.images) == 0:
                codename_json['thumbUrl'] = DEFAULT_THUMB_URL
            else:
                codename_json['thumbUrl'] = url_for(
                    'CodenameView:get_thumb',
                    slug=codename.slug,
                    image_id=codename.images[0].id
                )

            codenames_json.append(codename_json)

        return json({'codenames': codenames_json})

    @route('/index', methods=('POST',))
    def post(self):
        ''' Create a new codename. '''

        codename_json = request.get_json()

        if 'name' not in codename_json or codename_json['name'].strip() == '':
            return error('Name is a required field.')

        codename = Codename(codename_json['name'])

        # Make sure that the slug doesn't conflict with any static routes.
        for rule in flask_app.url_map.iter_rules():
            root = str(rule).split('/')[1]
            if root == codename.slug:
                message = 'Codename may not override static route: "%s".'
                return error(message % rule, 409)

        try:
            g.db.add(codename)
            g.db.commit()
        except IntegrityError:
            return error('Codename "%s" already exists.' % codename.name, 409)

        return success(
            'Codename "%s" created.' % codename.name,
            url=url_for('CodenameView:get', slug=codename.slug)
        )

    @route('/<slug>/images')
    def post_image(self, slug):
        ''' Add an image to a codename. '''

        raise NotImplementedError("You can't add an image yet!")

    @route('/<slug>/references', methods=('POST',))
    def post_reference(self, slug):
        ''' Add a reference to a codename. '''

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if codename is None:
            return not_found()

        reference_json = request.get_json()
        reference = Reference(
            reference_json['url'],
            reference_json['annotation']
        )
        codename.references.append(reference)
        codename.updated = datetime.today()

        g.db.add(reference)
        g.db.commit()

        return success(
            'Reference added to codename "%s".' % codename.name,
            url = url_for(
                "CodenameView:get_reference",
                slug=slug,
                reference_id=reference.id
            )
        )

    def put(self, slug):
        ''' Update a codename's summary or description. '''

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if codename is None:
            return not_found()

        codename_json = request.get_json()

        codename.summary = codename_json['summary']
        codename.description = codename_json['description']
        codename.updated = datetime.today()

        g.db.commit()

        return success('Codename "%s" updated.' % codename.name)

    @route('/<slug>/references/<int:reference_id>', methods=('PUT',))
    def put_reference(self, slug, reference_id):
        ''' Update a reference. '''

        reference = g.db.query(Reference) \
                        .filter(Reference.id == reference_id) \
                        .first()

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()

        if reference is None or codename is None or \
            reference.codename is not codename:

            return not_found()

        reference_json = request.get_json()
        reference.url = reference_json['url']
        reference.annotation = reference_json['annotation']
        codename.updated = datetime.today()

        g.db.commit()

        return success('Reference updated for codename "%s".' % codename.name)

    @route('/search')
    def search(self):
        ''' Perform a keyword search of codenames. '''

        query = request.args.get('q', '').strip()

        if query == '':
            return error('The query parameter "q" is required.')

        codenames = g.db.query(Codename) \
                        .filter(
                            Codename.name.like('%{0}%'.format(query)) |
                            Codename.summary.like('%{0}%'.format(query)) |
                            Codename.description.like('%{0}%'.format(query))
                        )

        codenames_json = list()

        for codename in codenames:
            codename_json = {
                'name': codename.name,
                'summary': codename.summary,
                'url': url_for('CodenameView:get', slug=codename.slug)
            }

            if len(codename.images) == 0:
                codename_json['thumbUrl'] = DEFAULT_THUMB_URL
            else:
                codename_json['thumbUrl'] = url_for(
                    'CodenameView:get_thumb',
                    slug=codename.slug,
                    image_id=codename.images[0].id
                )

            codenames_json.append(codename_json)

        return json({'codenames': codenames_json})
