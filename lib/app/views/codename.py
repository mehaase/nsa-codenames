from datetime import datetime
import hashlib
from io import BytesIO
import os

from flask import g, jsonify, request, send_from_directory
from flask.ext.classy import FlaskView, route
from PIL import Image as PILImage
from sqlalchemy.exc import IntegrityError
from werkzeug.exceptions import BadRequest, Conflict, NotFound

from app import flask_app
import app.config
from app.authorization import admin_required, login_optional, login_required
from app.rest import date_to_timestamp, url_for
from model import Codename, Image, Reference, User
from model.image import image_join_user

DEFAULT_IMAGE_URL = '/static/img/default-codename.png'
DEFAULT_THUMB_URL = '/static/img/default-codename-thumb.png'

class CodenameView(FlaskView):
    ''' API for Codename and related models. '''

    @route('/approval')
    @admin_required
    def approval(self):
        ''' List images that are pending approval. '''

        needs_approval = list()
        unapproved_images = g.db.query(Image) \
                                .join(Image.codename) \
                                .filter(Image.approved==False)

        for image in unapproved_images:
            approve_url = url_for(
                'CodenameView:approve_image',
                slug=image.codename.slug,
                image_id=image.id
            )

            codename_url = url_for(
                'CodenameView:get',
                slug=image.codename.slug
            )

            delete_url = url_for(
                'CodenameView:delete_image',
                slug=image.codename.slug,
                image_id=image.id
            )

            image_url = url_for(
                'CodenameView:get_image',
                slug=image.codename.slug,
                image_id=image.id
            )

            needs_approval.append({
                'approveUrl': approve_url,
                'codename': {
                    'name': image.codename.name,
                    'slug': image.codename.slug,
                    'url':  codename_url,
                },
                'contributor': {'username': image.contributor.username},
                'deleteUrl': delete_url,
                'imageUrl': image_url,
            })

        return jsonify(approvals=needs_approval)

    @route('/<slug>/approve/<int:image_id>', methods=('POST',))
    @admin_required
    def approve_image(self, slug, image_id):
        ''' Approve an image. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)

        image.approved = True
        g.db.commit()

        return jsonify(message='Image approved.')

    @admin_required
    def delete(self, slug):
        ''' Delete a codename. '''

        codename = self._get_codename_by_slug(slug)

        g.db.delete(codename)
        g.db.commit()

        return jsonify(message='Codename "%s" deleted.' % codename.name)

    @route('/<slug>/references/<int:reference_id>', methods=('DELETE',))
    @admin_required
    def delete_reference(self, slug, reference_id):
        ''' Delete a reference. '''

        codename = self._get_codename_by_slug(slug)
        reference = self._get_reference_for_codename(reference_id, codename)

        codename.updated = datetime.today()
        g.db.delete(reference)
        g.db.commit()

        message = 'Reference %d deleted from codename "%s".'
        return jsonify(message=message % (reference.id, codename.name))

    @route('/<slug>/images/<int:image_id>', methods=('DELETE',))
    @admin_required
    def delete_image(self, slug, image_id):
        ''' Delete an image from a codename. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)

        codename.updated = datetime.today()
        g.db.delete(image)
        g.db.commit()

        message = 'Image %d deleted from codename "%s".'
        return jsonify(message=message % (image.id, codename.name))

    @route('/<slug>/images/<int:image_id>/vote', methods=('DELETE',))
    @login_required
    def delete_image_vote(self, slug, image_id):
        ''' Remove a vote for an image. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)

        if g.user in image.voters:
            image.voters.remove(g.user)
            image.votes -= 1

        g.db.commit()

        return jsonify(
            voted=False,
            votes=image.votes
        )

    @login_optional
    def get(self, slug):
        ''' Get a codename. '''

        codename = self._get_codename_by_slug(slug)

        codename_json = {
            'name': codename.name,
            'slug': codename.slug,
            'summary': codename.summary,
            'description': codename.description,
            'added': date_to_timestamp(codename.added),
            'updated': date_to_timestamp(codename.updated),
            'images': list(),
            'references': list(),
        }

        for image in codename.images:
            voted = g.user in image.voters if g.user is not None else False

            if not image.approved and g.user is not image.contributor:
                continue

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
                'contributor': {'username': image.contributor.username},
                'voted': voted,
                'votes': image.votes,
                'approved': image.approved,
            })

        if len(codename_json['images']) == 0:
            codename_json['images'].append({
                'contributor': {'username': None},
                'url': DEFAULT_IMAGE_URL,
                'thumbUrl': DEFAULT_THUMB_URL,
                'voted': False,
                'votes': 0,
                'approved': True,
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

        return jsonify(**codename_json)

    @route('/<slug>/images/<int:image_id>')
    def get_image(self, slug, image_id):
        ''' Send an image. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)
        data_dir = app.config.get_path('data')

        return send_from_directory(data_dir, image.path)

    @route('/<slug>/images/<int:image_id>/approval')
    @login_optional
    def get_image_approval(self, slug, image_id):
        ''' Get an image's approval status. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)

        if g.user is not None:
            vote = g.db.query(Image) \
                       .join(Image.voters) \
                       .filter(User.id==g.user.id, Image.id==image_id) \
                       .count()
        else:
            vote = 0

        return jsonify(approved=image.approved)

    @route('/<slug>/images/<int:image_id>/vote')
    @login_optional
    def get_image_vote(self, slug, image_id):
        ''' Get a user's vote status. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)

        if g.user is not None:
            vote = g.db.query(Image) \
                       .join(Image.voters) \
                       .filter(User.id==g.user.id, Image.id==image_id) \
                       .count()
        else:
            vote = 0

        return jsonify(
            voted=(vote > 0),
            votes=image.votes
        )

    @route('/<slug>/references/<int:reference_id>')
    def get_reference(self, slug, reference_id):
        ''' Get a reference. '''

        codename = g.db.query(Codename).filter(Codename.slug == slug).first()
        reference = self._get_reference_for_codename(reference_id, codename)

        return jsonify(
            url=reference.url,
            annotation=reference.annotation
        )

    @route('/<slug>/images/<int:image_id>/thumbnail')
    def get_thumb(self, slug, image_id):
        ''' Send a thumbnail. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)
        data_dir = app.config.get_path('data')

        return send_from_directory(data_dir, image.thumb_path)

    @route('/')
    def index(self):
        ''' List codenames in alphabetical order. '''

        codenames = g.db.query(Codename).order_by(Codename.name)
        codenames_json = list()

        for codename in codenames:
            codename_json = {
                'name': codename.name,
                'slug': codename.slug,
                'url': url_for('CodenameView:get', slug=codename.slug)
            }

            if (len(codename.images) == 0):
                codename_json['thumbUrl'] = DEFAULT_THUMB_URL
            else:
                codename_json['thumbUrl'] = url_for(
                    'CodenameView:get_thumb',
                    slug=codename.slug,
                    image_id=codename.images[0].id
                )

            codenames_json.append(codename_json)

        return jsonify(codenames=codenames_json)

    @route('/', methods=('POST',))
    @admin_required
    def post(self):
        ''' Create a new codename. '''

        codename_json = request.get_json()

        if 'name' not in codename_json or codename_json['name'].strip() == '':
            raise BadRequest('Name is a required field.')

        codename = Codename(codename_json['name'])

        # Make sure that the slug doesn't conflict with any static routes.
        for rule in flask_app.url_map.iter_rules():
            root = str(rule).split('/')[1]
            if root == codename.slug:
                message = 'Codename may not override static route: "/%s".'
                raise Conflict(message % root)

        try:
            g.db.add(codename)
            g.db.commit()
        except IntegrityError:
            return Conflict('Codename "%s" already exists.' % codename.name)

        return jsonify(
            message='Codename "%s" created.' % codename.name,
            url=url_for('CodenameView:get', slug=codename.slug),
            slug=codename.slug
        )

    @route('/<slug>/images', methods=('POST',))
    @login_required
    def post_image(self, slug):
        '''
        Add an image to a codename.

        This only supports image/png and it expects images to be _exactly_
        720x400 pixels.
        '''

        REQUIRED_WIDTH = 720
        REQUIRED_HEIGHT = 400

        THUMB_WIDTH = 144
        THUMB_HEIGHT = 80

        codename = self._get_codename_by_slug(slug)

        # Parse the image to make sure it is valid.
        content_type = request.headers.get('content-type', '')
        image = PILImage.open(BytesIO(request.data))
        width, height = image.size

        if content_type.lower() != 'image/png' or image.format != 'PNG':
                raise BadRequest('Content type must be a valid image/png.')

        if width != REQUIRED_WIDTH or height != REQUIRED_HEIGHT:
            message = "Images must be exactly %d x %d pixels."
            args = (REQUIRED_WIDTH, REQUIRED_HEIGHT)
            raise BadRequest(message % args)

        # Save the file (if not already present).
        filename = hashlib.sha1(image.tobytes()).hexdigest() + '.png'
        dir_ = app.config.get_path('data')
        path = os.path.join(dir_, filename)

        if not os.path.exists(path):
            image.save(path)

        # Create and save a thumbnail (if not already present).
        image.thumbnail((THUMB_WIDTH, THUMB_HEIGHT))
        thumb_filename = hashlib.sha1(image.tobytes()).hexdigest() + '.png'
        thumb_path = os.path.join(dir_, thumb_filename)

        if not os.path.exists(thumb_path):
            image.save(thumb_path)

        # Create database object.
        image_obj = Image(filename, thumb_filename, g.user)
        codename.images.append(image_obj)
        g.db.commit()

        # Render response.
        url = url_for(
            'CodenameView:get_image',
            slug=slug,
            image_id=image_obj.id
        )

        thumb_url = url_for(
            'CodenameView:get_thumb',
            slug=slug,
            image_id=image_obj.id
        )

        return jsonify(
            url=url,
            thumbUrl=thumb_url,
            contributor={'username': image_obj.contributor.username},
            replace=(len(codename.images) == 1),
            votes=image_obj.votes,
            approved=image_obj.approved
        )

    @route('/<slug>/images/<int:image_id>/vote', methods=('POST',))
    @login_required
    def post_image_vote(self, slug, image_id):
        ''' Register a vote for an image. '''

        codename = self._get_codename_by_slug(slug)
        image = self._get_image_for_codename(image_id, codename)

        if g.user not in image.voters:
            image.voters.append(g.user)
            image.votes += 1

        g.db.commit()

        return jsonify(
            voted=True,
            votes=image.votes
        )

    @route('/<slug>/references', methods=('POST',))
    @admin_required
    def post_reference(self, slug):
        ''' Add a reference to a codename. '''

        codename = self._get_codename_by_slug(slug)

        reference_json = request.get_json()
        reference = Reference(
            reference_json['url'],
            reference_json['annotation']
        )

        codename.references.append(reference)
        codename.updated = datetime.today()

        g.db.add(reference)
        g.db.commit()

        return jsonify(
            message='Reference added to codename "%s".' % codename.name,
            url = url_for(
                "CodenameView:get_reference",
                slug=slug,
                reference_id=reference.id
            )
        )

    @admin_required
    def put(self, slug):
        ''' Update a codename's summary or description. '''

        codename_json = request.get_json()

        codename = self._get_codename_by_slug(slug)
        codename.summary = codename_json['summary']
        codename.description = codename_json['description']
        codename.updated = datetime.today()

        g.db.commit()

        return jsonify(message='Codename "%s" updated.' % codename.name)

    @route('/<slug>/references/<int:reference_id>', methods=('PUT',))
    @admin_required
    def put_reference(self, slug, reference_id):
        ''' Update a reference. '''

        codename = self._get_codename_by_slug(slug)
        reference = self._get_reference_for_codename(reference_id, codename)

        reference_json = request.get_json()
        reference.url = reference_json['url']
        reference.annotation = reference_json['annotation']

        codename.updated = datetime.today()

        g.db.commit()

        message = 'Reference updated for codename "%s".'
        return jsonify(message=message % codename.name)

    @route('/search')
    def search(self):
        ''' Perform a keyword search of names and summaries. '''

        query = request.args.get('q', '').strip()

        if query == '':
            return BadRequest('The query parameter "q" is required.')

        query = query.replace('%', '\%').replace('_', '\_')

        codenames = g.db.query(Codename) \
                        .filter(
                            Codename.name.like('%{0}%'.format(query)) |
                            Codename.summary.like('%{0}%'.format(query))
                        )

        codenames_json = list()

        for codename in codenames:
            codename_json = {
                'name': codename.name,
                'slug': codename.slug,
                'summary': codename.summary,
                'url': url_for('CodenameView:get', slug=codename.slug)
            }

            for image in codename.images:
                if image.approved:
                    codename_json['thumbUrl'] = url_for(
                        'CodenameView:get_thumb',
                        slug=codename.slug,
                        image_id=codename.images[0].id
                    )

                    break

            if 'thumbUrl' not in codename_json:
                codename_json['thumbUrl'] = DEFAULT_THUMB_URL

            codenames_json.append(codename_json)

        return jsonify(codenames=codenames_json)

    def _get_codename_by_slug(self, slug):
        ''' Get a codename object by its slug. '''

        codename = g.db.query(Codename) \
                       .filter(Codename.slug == slug) \
                       .first()

        if codename is None:
            raise NotFound('No codename exists for "%s" slug.' % slug)

        return codename

    def _get_image_for_codename(self, image_id, codename):
        ''' Get an image for a codename. '''

        image = g.db.query(Image) \
                        .filter(Image.id == image_id) \
                        .first()

        if image is None or image.codename is not codename:
            message = 'Image (%d) does not exist for this codename.'
            raise NotFound(message % image_id)

        return image

    def _get_reference_for_codename(self, reference_id, codename):
        ''' Get a reference for a codename. '''

        reference = g.db.query(Reference) \
                        .filter(Reference.id == reference_id) \
                        .first()

        if reference is None or reference.codename is not codename:
            message = 'Reference (%d) does not exist for this codename.'
            raise NotFound(message % reference_id)

        return reference
