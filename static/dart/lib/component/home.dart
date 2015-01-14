import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Component(
    selector: 'home',
    templateUrl: '/static/dart/web/packages/nsa_codenames/component/home.html',
    useShadowDom: false
)
class HomeComponent {
    AuthenticationController auth;

    String markdown;

    HomeComponent(this.auth) {
        HttpRequest.request('/api/content/home', requestHeaders:{'Accept': 'application/json'}).then((request) {
            Map json = JSON.decode(request.response);
            this.markdown = json['markdown'];
        });
    }

    Future save() {
        return HttpRequest.request(
            '/api/content/home',
            method: 'PUT',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
            sendData: JSON.encode({'markdown': this.markdown})
        );
    }
}
