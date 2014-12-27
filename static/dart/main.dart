import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
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
        bind(AboutComponent);
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

@Component(
    selector: 'about',
    templateUrl: '/static/html/components/about.html',
    useShadowDom: false
)
class AboutComponent {
    String html, markdown, updated;

    AboutComponent() {
        HttpRequest.getString('/content/about').then(this.onDataLoaded);
    }

    void onDataLoaded(String response) {
        Map json = JSON.decode(response);
        this.markdown = json['markdown'];
        this.html = context['markdown'].callMethod('toHTML', [this.markdown]);

        Datetime dt = new DateTime.fromMillisecondsSinceEpoch(json['updated']);
        this.updated = '${dt.year.toString()}-'
                     + '${dt.month.toString().padLeft(2, '0')}-'
                     + '${dt.day.toString().padLeft(2, '0')}';
    }
}

class Codename {
    String name, slug, summary, description;
    DateTime added, updated;
    List<Image> images;
    List<Reference> references;

    Codename.old(this.name, this.description);

    Codename(Map json) {
        this.name = json['name'];
        this.slug = json['slug'];
        this.summary = json['summary'];
        this.description = json['description'];

        this.added = new DateTime.fromMillisecondsSinceEpoch(json['added']);
        this.updated = new DateTime.fromMillisecondsSinceEpoch(json['updated']);

        this.images = new List<Image>();
        for (Map imageJson in json['images']) {
            this.images.add(new Image(imageJson));
        }

        this.references = new List<Reference>();
        for (Map referenceJson in json['references']) {
            this.references.add(new Reference(referenceJson));
        }
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
        String url = '/' + rp.parameters['codename'];
        HttpRequest.getString(url).then(this.onDataLoaded);
    }

    void onDataLoaded(String response) {
        Map json = JSON.decode(response);
        this.codename = new Codename(json);
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

class Image {
    String thumbUrl, url;

    Image(Map json) {
        this.thumbUrl = json['thumbUrl'];
        this.url = json['url'];
    }
}

@Component(
    selector: 'index',
    templateUrl: '/static/html/components/index.html',
    useShadowDom: false
)
class IndexComponent {
    List<String> letters;
    Map<String, List<CodenameResult>> codenamesByInitial;

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

        HttpRequest.getString('/index').then(this.onDataLoaded);
    }

    void onDataLoaded(String response) {
        Map json = JSON.decode(response);
        for (Map codenameJson in json['codenames']) {
            String initial = codenameJson['name'].substring(0, 1);

            this.codenamesByInitial[initial].add(
                new CodenameResult(codenameJson)
            );
        }
    }

    void scroll(String letter) {
        var element = querySelector("#" + letter);
        print(element);
        element.scrollIntoView(ScrollAlignment.TOP);
    }
}

class Reference {
    String annotation, externalUrl, url;

    Reference(Map json) {
        this.annotation = json['annotation'];
        this.externalUrl = json['externalUrl'];
        this.url = json['url'];
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
