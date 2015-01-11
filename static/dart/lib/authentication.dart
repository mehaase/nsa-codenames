import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/model/user.dart';

@Injectable()
class AuthenticationController {
    User currentUser;
    String token;

    Router _router;
    bool _redirect;

    Completer<bool> _loggedInCompleter;
    Completer<bool> _notLoggedInCompleter;

    AuthenticationController(Router router) {
        this._router = router;

        this._loggedInCompleter = new Completer<bool>();
        this._notLoggedInCompleter = new Completer<bool>();
        this._loggedInCompleter.future.then((isLoggedIn) {
            this._notLoggedInCompleter.complete(!isLoggedIn);
        });

        if (window.localStorage.containsKey('token')) {
            this.logIn(window.localStorage['token'], redirect: false);
        } else {
            this._loggedInCompleter.complete(false);
        }
    }

    void requireLogin(RoutePreEnterEvent e) {
        e.allowEnter(this._loggedInCompleter.future);

        this._loggedInCompleter.future.then((result) {
            if (!result) {
                this._router.go('login', {});
            }
        });
    }

    void requireNoLogin(RoutePreEnterEvent e) {
        e.allowEnter(this._notLoggedInCompleter.future);

        this._notLoggedInCompleter.future.then((result) {
            if (!result) {
                this._router.go('home', {});
            }
        });
    }

    bool isLoggedIn() {
        return currentUser != null;
    }

    bool isAdmin() {
        return isLoggedIn() && currentUser.isAdmin;
    }

    void logIn(String token, {bool redirect: true}) {
        this._redirect = redirect;
        this.token = token;
        window.localStorage['token'] = token;

        HttpRequest.request(
            '/api/user/whoami',
            requestHeaders: {'Auth': this.token, 'Accept': 'application/json'}
        ).then(this.continueLogin)
         .catchError((e) => window.localStorage.remove('token'));
    }

    void continueLogin(HttpRequest request) {
        var response = JSON.decode(request.response);

        if (response['id'] != null) {
            this.currentUser = new User();
            this.currentUser.id = response['id'];
            this.currentUser.username = response['username'];
            this.currentUser.imageUrl = response['image_url'];
            this.currentUser.isAdmin = response['is_admin'];

            if (!this._loggedInCompleter.isCompleted) {
                this._loggedInCompleter.complete(true);
            }
        } else {
            window.localStorage.remove('token');

            if (!this._loggedInCompleter.isCompleted) {
                this._loggedInCompleter.complete(false);
            }
        }

        if (this._redirect) {
            this._router.go('home', {});
        }
    }

    void logOut() {
        this.currentUser = null;
        this.token = null;
        window.localStorage.remove('token');

        if (this._router.activePath.first.name == 'login') {
            this._router.go('home', {});
        }
    }
}
