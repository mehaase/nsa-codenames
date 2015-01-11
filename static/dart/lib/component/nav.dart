import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Component(
    selector: 'nav',
    templateUrl: '/static/dart/web/packages/nsa_codenames/component/nav.html',
    useShadowDom: false
)
class NavComponent {
    AuthenticationController auth;

    NavComponent(AuthenticationController auth) {
        this.auth = auth;
    }
}
