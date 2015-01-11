import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Injectable()
class MyRouteInitializer implements Function {
    AuthenticationController auth;

    MyRouteInitializer(this.auth);

    void call(Router router, RouteViewFactory views) {
        views.configure({
            'about': ngRoute(
                path: '/about',
                view: '/static/dart/web/view/about.html'
            ),
            'codename': ngRoute(
                defaultRoute: true,
                path: '/:slug',
                view: '/static/dart/web/view/codename.html',
                preEnter: (e) {
                    if (e.parameters['slug'] == null) {
                        router.go('home', {});
                    }
                }
            ),
            'add-codename': ngRoute(
                path: '/add-codename',
                view: '/static/dart/web/view/add-codename.html',
                preEnter: auth.requireLogin
            ),
            'home': ngRoute(
                path: '/home',
                view: '/static/dart/web/view/home.html'
            ),
            'index': ngRoute(
                path: '/index',
                view: '/static/dart/web/view/index.html'
            ),
            'login': ngRoute(
                path: '/login',
                view: '/static/dart/web/view/login.html',
                preEnter: auth.requireNoLogin
            ),
            'moderate': ngRoute(
                path: '/moderate',
                view: '/static/dart/web/view/moderate.html',
                preEnter: auth.requireLogin
            ),
            'search': ngRoute(
                path: '/search',
                view: '/static/dart/web/view/search.html'
            ),
        });
    }
}

