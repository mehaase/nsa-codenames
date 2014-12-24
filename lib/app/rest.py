''' Utility functions for the REST API. '''

from datetime import datetime

from flask import json as flask_json, make_response

def dictify(object_, members, dict_=None):
    '''
    Expose scalar values of <object_> as a dict.

    E.g. if foo.bar == 2, then this will return a dict with key 'bar'
    and value 2.

    If <dict_> is specified, the object will be merged into it. Otherwise
    a new dict is returned.
    '''

    if dict_ is None:
        dict_ = dict()

    for member in members:
        value = getattr(object_, member)

        if isinstance(value, datetime):
            value = date_to_timestamp(value)

        dict_[member] = value

    return dict_

def date_to_timestamp(date_):
    ''' Python appallingly lacks a date -> epoch method. '''

    return (date_ - datetime.utcfromtimestamp(0)).total_seconds()

def json(serializable, status=200):
    ''' Create a JSON response. '''

    response = make_response(flask_json.dumps(serializable))
    response.headers['Content-Type'] = 'application/json; charset=utf8'

    return response

def not_found():
    ''' Indicates that a resource cannot be found. '''

    response = {error: True, message: "Not found."}
    return json(response, 404)
