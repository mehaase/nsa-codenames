''' Utility functions for the REST API. '''

from datetime import datetime

from flask import url_for as flask_url_for

def date_to_timestamp(date_):
    ''' Python appallingly lacks a date -> epoch method. '''

    return (date_ - datetime.utcfromtimestamp(0)).total_seconds()

def url_for(*args, **kwargs):
    ''' Override Flask's url_for to make all URLS fully qualified. '''

    kwargs['_external'] = True
    return flask_url_for(*args, **kwargs)
