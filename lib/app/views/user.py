''' Views for various authentication schemes. '''

from flask import abort, g, request, session
from flask.ext.classy import FlaskView, route

from app.rest import error, json, success
from model import User

class UserView(FlaskView):
    ''' Information about users. '''

    @route('/whoami')
    def whoami(self):
        ''' Return information about the current logged in user. '''

        response = {
            'id': None,
            'username': None,
            'image_url': None,
        }

        if 'user_id' in session:
            user = self._get_current_user()

            if user is None:
                del session['user_id']
            else:
                response['id'] = user.id
                response['username'] = user.username
                response['image_url'] = user.image_url

        return json(response)

    @route('/current/username', methods=('POST',))
    def change_username(self):
        ''' Allow a user to change his/her own username -- but only once. '''

        user = self._get_current_user()

        if user is None:
            return error('You are not logged in.', status=401)

        if not user.can_change_username:
            return error(
                'You are not allowed to change your username.',
                status=403
            )

        username_json = request.get_json()
        username = username_json['username']

        if username == user.username:
            return error(
                'The new username is the same as the old username.',
                status=400
            )

        user.username = username
        user.can_change_username = False
        g.db.commit()

        return success('Username changed successfully.')

    def _get_current_user(self):
        ''' Get the current user. '''

        user = g.db.query(User) \
                   .filter(User.id==session['user_id']) \
                   .first()

        return user
