""" Views for the index. """

from flask import render_template

from app import flask_app

@flask_app.route('/')
def root():
    """ Serves the main Angular template. """

    return render_template("root.html")
