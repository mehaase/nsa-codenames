''' Views for various authentication schemes. '''

from datetime import datetime

from flask import abort, g, request
from flask.ext.classy import FlaskView, route
from werkzeug.exceptions import BadRequest, Unauthorized

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
            'is_admin': False,
        }

        user = self._get_current_user()

        response = {
            'id': user.id,
            'username': user.username,
            'image_url': user.image_url,
            'is_admin': user.is_admin,
        }

        return json(response)

    @route('/whoami', methods=('POST',))
    def change_username(self):
        '''
        Allow a user to change his/her own username.

        A username can only be changed within 15 minutes after creating an
        account. This is done so that users can select their own username
        after creating an account but cannot freely change their username
        after establishing a reputation on this site.
        '''

        CHANGE_TIME = 15

        try:
            user = self._get_current_user()
        except:
            return error('You are not logged in.', status=401)

        user_account_age = datetime.today() - user.added

        if user_account_age.seconds > CHANGE_TIME * 60:
            return error(
                'You are only allowed to change your username within' \
                ' %d minutes of creating your account.' % CHANGE_TIME,
                status=403
            )

        request_json = request.get_json()
        user.username = request_json['username']
        g.db.commit()

        return success('Username changed successfully.')

    def _get_current_user(self):
        ''' Get a user by ID. '''

        try:
            user_id = int(g.unsign(request.headers['auth']))
        except:
            raise BadRequest("Invalid signature on auth token.")

        user = g.db.query(User) \
                   .filter(User.id==user_id) \
                   .first()

        if user is None:
            raise Unauthorized("Your user ID (%d) is invalid." % user_id)

        return user
