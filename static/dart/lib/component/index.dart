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
    List<CodenameResult> codenames;
    num count;
    List<String> letters;
    String page;
    QueryWatcher queryWatcher;

    final RouteProvider _rp;

    IndexComponent(this._rp) {
        this.letters = new List<String>.generate(
            26,
            (int index) => new String.fromCharCode(index + 0x41)
        );

        RouteHandle rh = this._rp.route.newHandle();

        // Listen for new routes.
        StreamSubscription subscription = rh.onEnter.listen((e) {
            this._fetchCurrentPage();
        });

        // Clean up the event listener when we leave the route.
        rh.onLeave.take(1).listen((_) {
            subscription.cancel();
        });

        this._fetchCurrentPage();
    }

    void _fetchCurrentPage() {
        this.page = Uri.decodeComponent(this._rp.parameters['page']);
        String url = '/api/codename?page=${this.page}';
        Map headers = {'Accept': 'application/json'};

        HttpRequest.request(url, requestHeaders:headers).then((request) {
            Map json = JSON.decode(request.response);
            this.count = json['count'];

            this.codenames = new List<CodenameResult>.generate(
                json['codenames'].length,
                (index) => new CodenameResult(json['codenames'][index])
            );
        });
    }
}
