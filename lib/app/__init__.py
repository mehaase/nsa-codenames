""" The main application package. """

from flask import Flask, g
from flask.ext.assets import Environment, Bundle
from flask_failsafe import failsafe

import app.config
import app.database

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

    # Initialize Flask.
    flask_app = MyFlask(
        __name__,
        static_folder=app.config.get_path("static"),
        template_folder=app.config.get_path("static/html")
    )
    flask_app.debug = debug

    config = app.config.get_config()

    # Run the bootstrap.
    init_flask(flask_app, config)
    init_flask_assets(flask_app, config)
    init_views(flask_app, config)

    return flask_app

def init_flask(flask_app, config):
    """ Initialize Flask configuration and hooks. """

    config_dict = dict(config.items('flask'))
    flask_app.config.update(**config_dict)

    # Disable caching for static assets in debug mode, otherwise
    # many Angular templates will be stale when refreshing pages.
    if flask_app.debug:
        flask_app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 0

    @flask_app.after_request
    def after_request(response):
        ''' Clean up request context. '''

        g.db.close()

        return response

    @flask_app.before_request
    def before_request():
        ''' Initialize request context. '''

        engine = app.database.get_engine(dict(config.items('database')))
        g.db = app.database.get_session(engine)

    @flask_app.before_first_request
    def before_first_request():
        ''' Initialize application context. '''

        g.debug = flask_app.debug

def init_flask_assets(flask_app, config):
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

def init_views(flask_app, config):
    """ Initialize views. """

    import app.views.angular

    from app.views.codename import CodenameView
    CodenameView.register(flask_app, route_base='/')

    from app.views.content import ContentView
    ContentView.register(flask_app, route_base='/content')
