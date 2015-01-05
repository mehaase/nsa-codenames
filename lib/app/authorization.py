from functools import wraps

from flask import g, request
from werkzeug.exceptions import BadRequest, Forbidden, Unauthorized

from model import User

def login_optional(original_function):
    '''
    A decorator that checks if a user is logged in.

    If the user is logged in, then the user object will be attached to 'g'.
    If the user is not logged in, then g.user will be None.
    '''

    @wraps(original_function)
    def wrapper(*args, **kwargs):
        g.user = _get_user_from_auth_header(required=False)
        return original_function(*args, **kwargs)

    return wrapper

def login_required(original_function):
    '''
    A decorator that requires a user to be logged in.

    A user is logged in if the user has a valid auth header that
    refers to a valid user object. If the user is logged in, then
    the user object will be attached to 'g'.
    '''

    @wraps(original_function)
    def wrapper(*args, **kwargs):
        g.user = _get_user_from_auth_header(required=True)
        return original_function(*args, **kwargs)

    return wrapper

def admin_required(original_function):
    '''
    A decorator that requires a logged in user to be an admin.

    If the user is an admin, then the user object will be attached
    to 'g'.
    '''

    @wraps(original_function)
    def wrapper(*args, **kwargs):
        user = _get_user_from_auth_header(required=True)

        if not user.is_admin:
            raise Forbidden("This request requires administrator privileges.")

        g.user = user

        return original_function(*args, **kwargs)

    return wrapper

def _get_user_from_auth_header(required=True):
    '''
    Try to read an auth token and load a corresponding user.

    If <required> is True, then this throws an exception on an
    invalid auth token or user ID.
    '''

    try:
        user_id = int(g.unsign(request.headers['auth']))
        user = g.db.query(User) \
                   .filter(User.id==user_id) \
                   .one()
    except:
        if required:
            raise Unauthorized("Invalid auth token.")
        else:
            return None

    return user
