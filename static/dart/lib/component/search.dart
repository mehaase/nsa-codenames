import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:nsa_codenames/model/codename-result.dart';

@Component(
    selector: 'search',
    templateUrl: 'packages/nsa_codenames/component/search.html',
    useShadowDom: false
)
class SearchComponent {
    String query, lastQuery;
    List<CodenameResult> results;
    Timer delay;
    String status = 'noQuery';
    bool showSpinner;

    SearchComponent() {
        results = new List<CodenameResult>();
    }

    void handleKeypress(KeyboardEvent ke) {
        if (delay != null) {
            delay.cancel();
        }

        if (ke.target.value.trim() == '') {
            this.status = 'noQuery';
        }

        delay = new Timer(new Duration(milliseconds: 500), search);
    }

    void search() {
        if (query.trim() != '') {
            String url = '/api/codename/search?q=' + this.query;
            HttpRequest.request(url, requestHeaders:{'Accept': 'application/json'}).then(this.onDataLoaded);
            this.showSpinner = true;
        }
    }

    void onDataLoaded(String request) {
        this.showSpinner = false;
        Map searchResults = JSON.decode(request.response);
        results.clear();

        if (searchResults['codenames'].length == 0) {
            this.status = 'queryHasNoResults';
        } else {
            this.status = 'queryHasResults';
        }

        lastQuery = query;

        for (var codename_json in searchResults['codenames']) {
            results.add(new CodenameResult(codename_json));
        }
    }
}
