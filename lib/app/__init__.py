""" The main application package. """

from flask import Flask
from flask_failsafe import failsafe

import app.config

flask_app = None

""" Bootstrap the Flask application and return a reference to it. """
@failsafe
def bootstrap():
    global flask_app

    if flask_app is not None:
        return flask_app

    flask_app = Flask(
        __name__,
        static_folder=app.config.get_path("static"),
        template_folder=app.config.get_path("templates")
    )
    config = app.config.get_config()

    init_flask(flask_app, config)
    init_views(flask_app, config)

    return flask_app

""" Initialize Flask configuration. """
def init_flask(app, config):

    config_dict = dict(config.items('flask'))
    flask_app.config.update(**config_dict)

""" Initialize views. """
def init_views(app, config):

    import app.views.index
