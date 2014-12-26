import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';

void routeInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'about': ngRoute(
        path: '/about',
        view: '/static/html/views/about.html'
    ),
    'home': ngRoute(
        defaultRoute: true,
        path: '/',
        view: '/static/html/views/home.html'
    ),
    'index': ngRoute(
        path: '/index',
        view: '/static/html/views/index.html'
    ),
    'search': ngRoute(
        path: '/search',
        view: '/static/html/views/search.html'
    ),
    'codename': ngRoute(
        path: '/cn/:codename',
        view: '/static/html/views/codename.html'
    ),
  });
}

// From http://stackoverflow.com/questions/21523063/how-can-i-know-on-the-first-page-load-what-the-current-route-is-from-within-a
@Decorator(selector: '[current-route]')
class CurrentRoute {
    Router router;
    Element element;

    CurrentRoute(Element element, Router router) {
        this.element = element;
        this.router = router;

        toggleActive();

        var subscription;
        router.onRouteStart.listen((e) {
            e.completed.then((_) {
                toggleActive();
            });
        });
    }

    bool isRoute() {
        if (router.activePath.isEmpty) {
            return false;
        }

        return element.attributes['current-route'] == router.activePath.first.name;
    }

    void toggleActive() {
        if (isRoute()) {
            element.classes.add('active');
        } else {
            element.classes.remove('active');
        }
    }
}

class NsaCodenamesAppModule extends Module {
    NsaCodenamesAppModule() {
        bind(CodenameComponent);
        bind(CodenameResultComponent);
        bind(CurrentRoute);
        bind(IndexComponent);
        bind(NavComponent);
        bind(SearchComponent);
        bind(RouteInitializerFn, toValue: routeInitializer);
        bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
    }
}

class Codename {
    String name, slug, summary, description;
    DateTime added, updated;
    // List<Image> images;
    // List<Reference> references;

    Codename.old(this.name, this.description);

    Codename(Map json) {
        this.name = json['name'];
        this.slug = json['slug'];
        this.summary = json['summary'];
        this.description = json['description'];
        // this.added = new DateTime.fromMillisecondsSinceEpoch(json['added']);
        // this.updated = new DateTime.fromMillisecondsSinceEpoch(json['updated']);
    }
}

@Component(
    selector: 'codename',
    templateUrl: '/static/html/components/codename.html',
    useShadowDom: false
)
class CodenameComponent {
    @NgOneWay('codename')
    Codename codename;

    CodenameComponent(RouteProvider rp) {
        // tempName = rp.parameters['codename'];
        codename = new Codename({'name':"AGGRAVATED AVATAR", 'description':'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.'});
    }
}

class CodenameResult {
    String slug, name, summary, url, thumbUrl;

    CodenameResult(Map json) {
        this.name = json['name'];
        this.slug = json['slug'];
        this.summary = json['summary'];
        this.url = json['url'];
        this.thumbUrl = json['thumbUrl'];
    }
}

@Component(
    selector: 'codename-result',
    templateUrl: '/static/html/components/codename-result.html',
    useShadowDom: false
)
class CodenameResultComponent {
    @NgOneWay('codename')
    CodenameResult codename;
}


@Component(
    selector: 'nav',
    templateUrl: '/static/html/components/nav.html',
    useShadowDom: false
)
class NavComponent {

}

@Component(
    selector: 'index',
    templateUrl: '/static/html/components/index.html',
    useShadowDom: false
)
class IndexComponent {
    List<String> letters;
    Map<String, List<String>> codenamesByInitial;

    IndexComponent() {
        letters = new List<String>.generate(
            26,
            (int index) => new String.fromCharCode(index + 0x41)
        );

        codenamesByInitial = new Map.fromIterable(
            letters,
            key: (item) => item,
            value: (item) => new List<String>()
        );

        codenamesByInitial['A'].add('AGGRAVATED AVATAR');
        codenamesByInitial['A'].add('AMUSED BOUCHE');
        codenamesByInitial['B'].add('BORED BOXER');
        codenamesByInitial['D'].add('DULL DANDRUFF');
        codenamesByInitial['Z'].add('ZEALOUS ZEBRA');
    }

    void scroll(String letter) {
        var element = querySelector("#" + letter);
        print(element);
        element.scrollIntoView(ScrollAlignment.TOP);
    }
}

@Component(
    selector: 'search',
    templateUrl: '/static/html/components/search.html',
    useShadowDom: false
)
class SearchComponent {
    String query, lastQuery;
    List<CodenameResult> results;
    Timer delay;
    String status = 'noQuery';
    Element spinner;

    SearchComponent() {
        results = new List<Codename>();
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
        if (spinner == null) {
            spinner = querySelector('img.spinner');
        }

        if (query.trim() != '') {
            String url = '/search?q=' + this.query;
            HttpRequest.getString(url).then(this.onDataLoaded);
            spinner.classes.remove('hide');
        }
    }

    void onDataLoaded(String response) {
        spinner.classes.add('hide');
        Map searchResults = JSON.decode(response);
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

void main() {
    applicationFactory()
        .addModule(new NsaCodenamesAppModule())
        .run();
}
