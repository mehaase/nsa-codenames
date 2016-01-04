from flask import Flask, g, jsonify, make_response, request
from flask.ext.assets import Environment, Bundle
from flask_failsafe import failsafe
from itsdangerous import Signer

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
def bootstrap(debug=False, debug_db=False):
    """ Bootstrap the Flask application and return a reference to it. """

    global flask_app

    if flask_app is not None:
        return flask_app

    # Initialize Flask.
    flask_app = MyFlask(
        __name__,
        static_folder=app.config.get_path("static"),
        template_folder=app.config.get_path("lib/app/templates")
    )
    flask_app.debug = debug
    flask_app.debug_db = debug_db

    config = app.config.get_config()

    # Run the bootstrap.
    init_flask(flask_app, config)
    init_errors(flask_app, config)
    init_webassets(flask_app, config)
    init_views(flask_app, config)

    return flask_app


def init_errors(flask_app, config):
    ''' Initialize error handlers. '''

    def http_error_handler(error):
        '''
        An error handler that will convert errors to JSON format if necessary.
        '''

        # Should use a real mime parser here…
        mimetype = request.headers.get('accept', '').strip()

        if mimetype.startswith('application/json'):
            response = jsonify(message=error.description)
        elif hasattr(error, 'description'):
            response = make_response(error.description)
            response.headers['Content-type'] = 'text/plain'
        else:
            raise

        response.status_code = error.code

        return response

    http_status_codes = list(range(400,418)) + list(range(500,506))

    for http_status_code in http_status_codes:
        flask_app.errorhandler(http_status_code)(http_error_handler)


def init_flask(flask_app, config):
    """ Initialize Flask configuration and hooks. """

    config_dict = dict(config.items('flask'))

    # Try to convert numeric arguments to integers.
    for k, v in config_dict.items():
        try:
            config_dict[k] = int(v)
        except:
            pass

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
        g.config = config

        signer = Signer(config.get('flask', 'SECRET_KEY'))
        g.sign = lambda s: signer.sign(str(s).encode('utf8')).decode('utf-8')
        g.unsign = signer.unsign

        g.debug = flask_app.debug

    @flask_app.url_defaults
    def static_asset_cache_busting(endpoint, values):
        if endpoint == 'static' and 'filename' in values:
            filename = values['filename']
            if filename.startswith('img') or \
               filename.startswith('fonts'):

                values['version'] = flask_app.config['VERSION']


def init_logging(flask_app, config):
    """
    Set up logging.

    Flask automatically writes to stderr in debug mode, so we only configure
    the Flask log in production mode.
    """

    log_string_format = '%(asctime)s [%(name)s] %(levelname)s: %(message)s'
    log_date_format = '%Y-%m-%d %H:%M:%S'
    log_formatter = logging.Formatter(log_string_format, log_date_format)

    try:
        log_level = getattr(logging, config.get('logging', 'log_level').upper())
    except AttributeError:
        raise ValueError("Invalid log level: %s" % log_level)

    if not flask_app.debug:
        log_file = config.get('logging', 'log_file')
        log_handler = logging.FileHandler(log_file)
        log_handler.setLevel(log_level)
        log_handler.setFormatter(log_formatter)

        flask_app.logger.addHandler(log_handler)

    if flask_app.debug_db:
        # SQL Alchemy logging is very verbose and is only turned on when
        # explicitly asked for.
        db_log_handler = logging.StreamHandler(sys.stderr)
        db_log_handler.setFormatter(log_formatter)

        db_logger = logging.getLogger('sqlalchemy.engine')
        db_logger.setLevel(logging.INFO)
        db_logger.addHandler(db_log_handler)


def init_views(flask_app, config):
    """ Initialize views. """

    from app.views.authenticate import TwitterAuthenticationView
    TwitterAuthenticationView.register(
        flask_app,
        route_base='/api/authenticate/twitter'
    )

    from app.views.codename import CodenameView
    CodenameView.register(flask_app, route_base='/api/codename')

    from app.views.content import ContentView
    ContentView.register(flask_app, route_base='/api/content')

    from app.views.user import UserView
    UserView.register(flask_app, route_base='/api/user')

    # Make sure to import the Angular view last so that it will match
    # all remaining routes.
    import app.views.angular


def init_webassets(flask_app, config):
    """ Initialize Flask-Assets extension. """

    assets = Environment(flask_app)
    assets.debug = flask_app.debug
    dart_root = 'dart/web' if flask_app.debug else 'dart/build/web'

    assets.register("less",  Bundle(
        "less/bootstrap/bootstrap.less",
        "less/font-awesome/font-awesome.less",
        filters="less,cssmin",
        output="combined/combined.css",
        depends="less/*.less"
    ))

    assets.register('dart', Bundle(
        dart_root + '/main.dart'
    ))

    assets.register("javascript", Bundle(
        'js/markdown.js',
        dart_root + '/packages/web_components/dart_support.js',
        dart_root + '/packages/browser/dart.js',
        filters='jsmin',
        output='combined/combined.js'
    ))
