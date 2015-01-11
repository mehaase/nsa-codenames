import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Component(
    selector: 'add-codename',
    templateUrl: '/static/dart/web/packages/nsa_codenames/component/add-codename.html',
    useShadowDom: false
)
class AddCodenameComponent {
    AuthenticationController auth;
    Router router;

    String name='', error;
    bool disableButtons = false, showSpinner = false;

    AddCodenameComponent(this.auth, this.router);

    void saveCodename() {
        this.error = null;
        this.showSpinner = true;

        HttpRequest.request(
            '/api/codename/',
            method: 'POST',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
            sendData: JSON.encode({'name': this.name})
        ).then((request) {
            var response = JSON.decode(request.response);
            this.router.go('codename', {'slug': response['slug']});
        }).catchError((e) {
            var response = JSON.decode(e.target.responseText);
            this.error = response['message'];
        }).whenComplete(() {
            this.showSpinner = false;
        });
    }
}

