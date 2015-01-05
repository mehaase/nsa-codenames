''' Views for various authentication schemes. '''

from datetime import datetime

from flask import abort, g, jsonify, request
from flask.ext.classy import FlaskView, route
from werkzeug.exceptions import BadRequest, Unauthorized

from app.authorization import login_required
from model import User

class UserView(FlaskView):
    ''' Information about users. '''

    @route('/whoami')
    @login_required
    def whoami(self):
        ''' Return information about the current logged in user. '''

        return jsonify(
            id=g.user.id,
            username=g.user.username,
            image_url=g.user.image_url,
            is_admin=g.user.is_admin
        )

    @route('/whoami', methods=('POST',))
    @login_required
    def change_username(self):
        '''
        Allow a user to change his/her own username.

        A username can only be changed within 15 minutes after creating an
        account. This is done so that users can select their own username
        after creating an account but cannot freely change their username
        after establishing a reputation on this site.
        '''

        CHANGE_TIME = 15

        user_account_age = datetime.today() - g.user.added

        if user_account_age.seconds > CHANGE_TIME * 60:
            message =  'You are only allowed to change your username within' \
                       ' %d minutes of creating your account.' % CHANGE_TIME,
            raise Unauthorized(message)

        request_json = request.get_json()
        g.user.username = request_json['username']
        g.db.commit()

        return jsonify(message='Username changed successfully.')
