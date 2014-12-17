""" Views for static files. """

from app import flask_app

@flask_app.route('/')
def index():
    return flask_app.send_static_file('html/index.html')
