import 'dart:html';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';

void routeInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'about': ngRoute(
        path: '/about',
        view: '/static/html/about.html'
    ),
    'home': ngRoute(
        defaultRoute: true,
        path: '/',
        view: '/static/html/home.html'
    ),
    'index': ngRoute(
        path: '/index',
        view: '/static/html/index.html'
    ),
    'search': ngRoute(
        path: '/search',
        view: '/static/html/search.html'
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

class MyAppModule extends Module {
    MyAppModule() {
        bind(CurrentRoute);
        bind(NavComponent);
        bind(RouteInitializerFn, toValue: routeInitializer);
        bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
    }
}

@Component(
    selector: 'nav',
    templateUrl: '/static/html/nav.html',
    useShadowDom: false
)
class NavComponent {

}

void main() {
    applicationFactory()
        .addModule(new MyAppModule())
        .run();
}
