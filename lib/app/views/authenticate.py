''' Views for various authentication schemes. '''

from flask import g, json as flask_json, request, session
from flask.ext.classy import FlaskView, route
from requests_oauthlib import OAuth1Session

from app.rest import json, success
from model import User

class TwitterAuthenticationView(FlaskView):
    ''' Authentication scheme for Twitter. '''

    TWITTER_API_URL = 'https://api.twitter.com/'

    @route('/')
    def get_token(self):
        '''
        Request a token from the Twitter API and return a URL
        where the user can authorize this application.

        This is Twitter auth step 1.

        See: https://dev.twitter.com/web/sign-in/implementing
        '''

        request_token_url = self._url('oauth/request_token')
        authorization_url = self._url('oauth/authorize')

        oauth = OAuth1Session(
            client_key=g.config.get('twitter', 'client_key'),
            client_secret=g.config.get('twitter', 'client_secret')
        )

        response = oauth.fetch_request_token(request_token_url)

        response = {
            'url': oauth.authorization_url(authorization_url),
            'resource_owner_key': response['oauth_token'],
            'resource_owner_secret': response['oauth_token_secret'],
        }

        return json(response)

    @route('/', methods=('POST',))
    def post_verifier(self):
        '''
        Verify the authorization.

        This requires a JSON payload containing the redirect URL, resource
        owner key, and resource owner secret.

        This will obtain an access token on behalf of the user and insert
        it into a user object, creating the object first if necessary.
        '''

        oauth_json = request.get_json()
        access_token = self._get_access_token(oauth_json)
        user_info = self._get_user_info(access_token)

        user = g.db.query(User) \
                   .filter(User.oauth_provider=='twitter') \
                   .filter(User.oauth_user_id.like(user_info['id_str'])) \
                   .first()

        if user is None:
            user = User("twitter:%s" % user_info['id_str'])
            user.image_url = user_info['profile_image_url_https']
            user.oauth_provider = 'twitter'
            g.db.add(user)

            pick_username = True
        else:
            pick_username = False

        user.oauth_user_id = user_info['id_str']
        user.oauth_token = access_token['resource_owner_key']
        user.oauth_secret = access_token['resource_owner_secret']

        g.db.commit()

        session['user_id'] = user.id

        return success(
            'Twitter authentication is successful.',
            pick_username=pick_username
        )

    def _get_access_token(self, oauth_json):
        ''' Get an access token for a user. '''

        access_token_url = self._url('oauth/access_token')

        oauth = OAuth1Session(
            client_key=g.config.get('twitter', 'client_key'),
            client_secret=g.config.get('twitter', 'client_secret'),
            resource_owner_key=oauth_json['resource_owner_key'],
            resource_owner_secret=oauth_json['resource_owner_secret']
        )

        parsed = oauth.parse_authorization_response(oauth_json['url'])
        oauth.verifier = parsed['oauth_verifier']

        response = oauth.fetch_access_token(access_token_url)

        return {
            'resource_owner_key': response['oauth_token'],
            'resource_owner_secret': response['oauth_token_secret'],
        }

    def _get_user_info(self, access_token):
        ''' Get information about a user. '''

        user_info_url = self._url('1.1/account/verify_credentials.json') \
                      + '?skip_status=true'

        oauth = OAuth1Session(
            client_key=g.config.get('twitter', 'client_key'),
            client_secret=g.config.get('twitter', 'client_secret'),
            resource_owner_key=access_token['resource_owner_key'],
            resource_owner_secret=access_token['resource_owner_secret']
        )

        response = oauth.get(user_info_url)

        return flask_json.loads(response.text)

    def _url(self, path):
        ''' Construct a Twitter API URL. '''

        return TwitterAuthenticationView.TWITTER_API_URL + path
