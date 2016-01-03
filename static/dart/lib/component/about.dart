import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:nsa_codenames/authentication.dart';
import 'package:nsa_codenames/component/title.dart';

@Component(
    selector: 'about',
    templateUrl: 'packages/nsa_codenames/component/about.html',
    useShadowDom: false
)
class AboutComponent {
    AuthenticationController auth;

    String markdown;
    DateTime updated;
    TitleService ts;

    AboutComponent(this.auth, this.ts) {
        this.ts.title = 'About';
        String url = '/api/content/about';
        Map headers = {'Accept': 'application/json'};

        HttpRequest
            .request(url, requestHeaders:headers)
            .then((request) {
                Map json = JSON.decode(request.response);
                this.markdown = json['markdown'];
                // Dart uses milliseconds instead of seconds:
                int ts = json['updated'] * 1000;
                this.updated = new DateTime.fromMillisecondsSinceEpoch(ts);
            });
    }

    Future save() {
        Map headers = {
            'Auth': auth.token,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        };

        return HttpRequest.request(
            '/api/content/about',
            method: 'PUT',
            requestHeaders: headers,
            sendData: JSON.encode({'markdown': this.markdown})
        ).then((request) {
            this.updated = new DateTime.now();
        });
    }
}

