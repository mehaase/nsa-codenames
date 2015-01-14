import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Component(
    selector: 'login',
    templateUrl: '/static/dart/web/packages/nsa_codenames/component/login.html',
    useShadowDom: false
)
class LoginComponent {
    AuthenticationController auth;

    String redirectUrl, resourceOwnerKey, resourceOwnerSecret, username='';
    String apiUrl = '/api/authenticate/twitter/';

    bool disableButtons = false;
    bool showPopupWarning = false;
    bool showUsernamePrompt = false;
    bool showSpinner = false;

    Window popup;
    Timer popupTimer;

    LoginComponent(AuthenticationController auth) {
        this.auth = auth;
    }

    void startTwitter() {
        if (this.popup != null) {
            this.popup.close();
            this.popup = null;
        }

        this.disableButtons = true;
        HttpRequest.request(this.apiUrl, requestHeaders:{'Accept': 'application/json'}).then(this.continueTwitter);
        this.showSpinner = true;
    }

    void continueTwitter(String request) {
        Map response = JSON.decode(request.response);

        this.resourceOwnerKey = response['resource_owner_key'];
        this.resourceOwnerSecret = response['resource_owner_secret'];
        this.popup = window.open(
            response['url'],
            'Log In With Twitter',
            'width=600,height=400'
        );

        // If the popup is closed without completing the workflow, then
        // reset the UI.
        this.popupTimer = new Timer.periodic(
            new Duration(milliseconds: 500),
            (event) {
                if (this.popup != null && this.popup.closed) {
                    this.disableButtons = false;
                    this.showSpinner = false;
                    this.popupTimer.cancel();
                }
            }
        );

        // Wait for the workflow to complete, then finish authentication.
        if (this.popup == null) {
            this.showPopupWarning = true;
        } else {
            window.addEventListener('message', (event) {
                if (event.data.substring(0,4) == 'http') {
                    this.popup.close();
                    this.popupTimer.cancel();
                    this.redirectUrl = event.data;
                    finishTwitter();
                }
            });
        }
    }

    void finishTwitter() {
        Map<String,String> postData = {
            'resource_owner_key': this.resourceOwnerKey,
            'resource_owner_secret': this.resourceOwnerSecret,
            'url': this.redirectUrl
        };

        Map<String,String> headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        };

        HttpRequest.request(
            this.apiUrl,
            method: 'POST',
            requestHeaders: headers,
            sendData: JSON.encode(postData)
        ).then((request) {
            Map<String,String> response = JSON.decode(request.response);
            this.showSpinner = false;

            if (response['pick_username']) {
                this.showUsernamePrompt = true;
                this.disableButtons = false;
                this.auth.logIn(response['token'], redirect: false);
            } else {
                this.auth.logIn(response['token'], redirect: true);
            }
        });
    }

    void saveUsername() {
        this.disableButtons = true;
        this.showSpinner = true;

        HttpRequest.request(
            '/api/user/whoami',
            method: 'POST',
            requestHeaders: {'Auth': this.auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
            sendData: JSON.encode({'username': username})
        ).then((request) {
            this.auth.logIn(this.auth.token, redirect: true);
        }).whenComplete(() {
            this.showSpinner = false;
        });
    }
}
