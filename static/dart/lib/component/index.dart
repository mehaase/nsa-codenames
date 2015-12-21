import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/model/codename-result.dart';

@Component(
    selector: 'index',
    templateUrl: 'packages/nsa_codenames/component/index.html',
    useShadowDom: false
)
class IndexComponent {
    List<String> letters;
    Map<String, List<CodenameResult>> codenamesByInitial;

    IndexComponent() {
        this.letters = new List<String>.generate(
            26,
            (int index) => new String.fromCharCode(index + 0x41)
        );

        this.codenamesByInitial = new Map.fromIterable(
            letters,
            key: (item) => item,
            value: (item) => new List<String>()
        );

        HttpRequest.request('/api/codename/', requestHeaders:{'Accept': 'application/json'}).then((request) {
            Map json = JSON.decode(request.response);

            for (Map codenameJson in json['codenames']) {
                String initial = codenameJson['name'].substring(0, 1)
                                                     .toUpperCase();

                this.codenamesByInitial[initial].add(
                    new CodenameResult(codenameJson)
                );
            }
        });
    }

    void scroll(String letter) {
        var element = querySelector("#" + letter);
        element.scrollIntoView(ScrollAlignment.TOP);
    }
}
