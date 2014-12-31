from functools import wraps

from flask import g, request
from werkzeug.exceptions import BadRequest, Forbidden, Unauthorized

from model import User

def requires_login(original_function):
    '''
    A decorator that requires a user to be logged in.

    A user is logged in if the user has a valid auth header that
    refers to a valid user object. If the user is logged in, then
    the user object will be attached to 'g'.
    '''

    @wraps(original_function)
    def wrapper(*args, **kwargs):
        g.user = _get_user_from_auth_header()
        return original_function(*args, **kwargs)

    return wrapper

def requires_admin(original_function):
    '''
    A decorator that requires a logged in user to be an admin.

    If the user is an admin, then the user object will be attached
    to 'g'.
    '''

    @wraps(original_function)
    def wrapper(*args, **kwargs):
        user = _get_user_from_auth_header()

        if not user.is_admin:
            raise Forbidden("This request requires administrator privileges.")

        g.user = user

        return original_function(*args, **kwargs)

    return wrapper

def _get_user_from_auth_header():
    '''
    Try to read an auth token and load a corresponding user.

    Throws an exception if the auth token or user are invalid.
    '''

    try:
        user_id = int(g.unsign(request.headers['auth']))
        user = g.db.query(User) \
                   .filter(User.id==user_id) \
                   .one()
    except:
        raise Unauthorized("Invalid auth token.")

    return user
