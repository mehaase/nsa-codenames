""" The main application package. """

from flask import Flask
from flask.ext.assets import Environment, Bundle
from flask_failsafe import failsafe

import app.config

flask_app = None

class MyFlask(Flask):
    """
    Customized Flask subclass.

    Features:
     * Changes jinja2 delimiters from {{foo}} to [[foo]].
    """

    jinja_options = Flask.jinja_options.copy()
    jinja_options.update({
        "block_start_string": "[%",
        "block_end_string":   "%]",
        "variable_start_string": "[[",
        "variable_end_string":   "]]",
        "comment_start_string": "[#",
        "comment_end_string":   "#]",
    })

@failsafe
def bootstrap(debug=False):
    """ Bootstrap the Flask application and return a reference to it. """

    global flask_app

    if flask_app is not None:
        return flask_app

    flask_app = MyFlask(
        __name__,
        static_folder=app.config.get_path("static"),
        template_folder=app.config.get_path("static/html")
    )
    flask_app.debug = debug

    config = app.config.get_config()

    init_flask(flask_app, config)
    init_flask_assets(flask_app, config)
    init_views(flask_app, config)

    return flask_app

def init_flask(app, config):
    """ Initialize Flask configuration. """

    config_dict = dict(config.items('flask'))
    flask_app.config.update(**config_dict)

def init_flask_assets(app, config):
    """ Initialize Flask-Assets extension. """

    assets = Environment(flask_app)
    assets.debug = flask_app.debug

    less = Bundle(
        "less/bootstrap.less",
        filters="less, cssmin",
        output="combined/bootstrap.css",
        depends="less/*.less"
    )

    assets.register("less_all", less)

    js = Bundle(
        'dart/packages/web_components/platform.js',
        'dart/packages/web_components/dart_support.js',
        filters='jsmin',
        output='combined/combined.js'
    )

    assets.register("js_all", js)

def init_views(app, config):
    """ Initialize views. """

    import app.views.index
