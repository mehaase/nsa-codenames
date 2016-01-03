import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:nsa_codenames/component/title.dart';
import 'package:nsa_codenames/model/codename-result.dart';
import 'package:nsa_codenames/query_watcher.dart';

@Component(
    selector: 'search',
    templateUrl: 'packages/nsa_codenames/component/search.html',
    useShadowDom: false
)
class SearchComponent {
    String lastQuery, nextQuery;
    List<CodenameResult> results;
    Timer delay;
    bool loading = false;
    String status = 'noQuery';
    bool showSpinner;
    TitleService ts;

    QueryWatcher _queryWatcher;
    Router _router;
    RouteProvider _rp;

    SearchComponent(this._router, this._rp, this.ts) {
        this.ts.title = 'Search';

        this._queryWatcher = new QueryWatcher(
            this._rp.route.newHandle(),
            ['q'],
            this._fetchResults
        );

        this._fetchResults();
    }

    void handleKeypress(KeyboardEvent ke) {
        if (delay != null) {
            delay.cancel();
        }

        if (ke.target.value.trim() == '') {
            this.status = 'noQuery';
        } else if (nextQuery == lastQuery) {
            this.loading = false;
        } else if (nextQuery != lastQuery) {
            this.loading = true;
            delay = new Timer(new Duration(milliseconds: 500), search);
        }
    }

    void search() {
        this._router.go('search', {}, queryParameters: {'q': this.nextQuery});
    }

    void _fetchResults() {
        results = new List<CodenameResult>();
        String query = this._queryWatcher['q'];

        if (query == null || query.trim() == '') {
            this.loading = false;
            return;
        }

        this.ts.title = 'Search "${query}"';
        Map headers = {'Accept': 'application/json'};
        String url = '/api/codename/search?q=' + query;

        HttpRequest
            .request(url, requestHeaders:headers)
            .then((request) {
                Map searchResults = JSON.decode(request.response);
                results.clear();

                if (searchResults['codenames'].length == 0) {
                    this.status = 'queryHasNoResults';
                } else {
                    this.status = 'queryHasResults';
                }

                this.lastQuery = query;

                for (var codename_json in searchResults['codenames']) {
                    results.add(new CodenameResult(codename_json));
                }
            })
            .whenComplete(() {
                this.loading = false;
            });
    }
}
