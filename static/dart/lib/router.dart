import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Injectable()
class NsaCodenamesRouteInitializer implements Function {
    AuthenticationController auth;

    NsaCodenamesRouteInitializer(this.auth);

    void call(Router router, RouteViewFactory views) {
        views.configure({
            'about': ngRoute(
                path: '/about',
                viewHtml: '<about></about>'
            ),
            'add-codename': ngRoute(
                path: '/add-codename',
                viewHtml: '<add-codename></add-codename>',
                preEnter: auth.requireLogin
            ),
            'codename': ngRoute(
                defaultRoute: true,
                path: '/:slug',
                viewHtml: '<codename></codename>',
                preEnter: (e) {
                    if (e.parameters['slug'] == null) {
                        router.go('home', {});
                    }
                }
            ),
            'home': ngRoute(
                path: '/home',
                viewHtml: '<home></home>'
            ),
            'index': ngRoute(
                path: '/index/:page',
                dontLeaveOnParamChanges: true,
                viewHtml: '<index></index>'
            ),
            'login': ngRoute(
                path: '/login',
                viewHtml: '<login></login>',
                preEnter: auth.requireNoLogin
            ),
            'moderate': ngRoute(
                path: '/moderate',
                viewHtml: '<moderate></moderate>',
                preEnter: auth.requireLogin
            ),
            'search': ngRoute(
                path: '/search',
                viewHtml: '<search></search>'
            ),
        });
    }
}

