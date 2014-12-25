''' Utility functions for the REST API. '''

from datetime import datetime

from flask import json as flask_json, make_response, url_for as flask_url_for

def date_to_timestamp(date_):
    ''' Python appallingly lacks a date -> epoch method. '''

    return (date_ - datetime.utcfromtimestamp(0)).total_seconds()

def error(message, status=400):
    ''' Return a client error response. '''

    response = {'error': True, 'message': message}
    return json(response, status)

def json(serializable, status=200):
    ''' Create a JSON response. '''

    response = make_response(flask_json.dumps(serializable))
    response.headers['Content-Type'] = 'application/json; charset=utf8'

    return response, status

def not_found():
    ''' Indicates that a resource cannot be found. '''

    response = {'error': True, 'message': 'Not found.'}
    return json(response, 404)

def success(message, **kwargs):
    ''' Indicates a successful operation with no content. '''

    response = {'error': False, 'message': message}
    response.update(kwargs)

    return json(response)

def url_for(*args, **kwargs):
    ''' Override Flask's url_for to make all URLS fully qualified. '''

    kwargs['_external'] = True
    return flask_url_for(*args, **kwargs)
