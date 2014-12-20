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

@Component(
    selector: 'codename',
    templateUrl: '/static/html/components/codename.html',
    useShadowDom: false
)
class CodenameComponent {
    @NgOneWay('codename')
    Codename codename;
    String tempName;

    CodenameComponent(RouteProvider rp) {
        tempName = rp.parameters['codename'];
        codename = new Codename("AGGRAVATED AVATAR", 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.');
    }
}

@Component(
    selector: 'codename-result',
    templateUrl: '/static/html/components/codename-result.html',
    useShadowDom: false
)
class CodenameResultComponent {
    @NgOneWay('codename')
    Codename codename;
}

class Codename {
    String id;
    String name;
    String description;

    Codename(this.name, this.description);
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
    String query;
    List<Codename> results;

    SearchComponent() {
        results = new List<Codename>();

        results.add(new Codename("AGGRAVATED AVATAR", 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.'));
        results.add(new Codename("AMUSED BOUCHE", 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.'));
        results.add(new Codename("BORED BOXER", 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.'));
        results.add(new Codename("DULL DANDRUFF", 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.'));
        results.add(new Codename("ZEALOUS ZEBRA", 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed enim ipsum, pulvinar quis malesuada vel, consequat at ex. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse in volutpat lacus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu tristique arcu. Proin placerat turpis justo. Nunc lacinia tempus augue.'));
    }
}

void main() {
    applicationFactory()
        .addModule(new NsaCodenamesAppModule())
        .run();
}
