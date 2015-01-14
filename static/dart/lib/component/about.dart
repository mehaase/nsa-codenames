import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Component(
    selector: 'about',
    templateUrl: '/static/dart/web/packages/nsa_codenames/component/about.html',
    useShadowDom: false
)
class AboutComponent {
    AuthenticationController auth;

    String markdown;
    DateTime updated;

    AboutComponent(this.auth) {
        HttpRequest.request('/api/content/about', requestHeaders:{'Accept': 'application/json'}).then((request) {
            Map json = JSON.decode(request.response);
            this.markdown = json['markdown'];
            // Dart uses milliseconds instead of seconds:
            int timestamp = json['updated'] * 1000;
            this.updated = new DateTime.fromMillisecondsSinceEpoch(timestamp);
        });
    }

    Future save() {
        return HttpRequest.request(
            '/api/content/about',
            method: 'PUT',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
            sendData: JSON.encode({'markdown': this.markdown})
        ).then((request) {
            this.updated = new DateTime.now();
        });
    }
}

