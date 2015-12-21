import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';

@Component(
    selector: 'nav',
    templateUrl: 'packages/nsa_codenames/component/nav.html',
    useShadowDom: false
)
class NavComponent {
    AuthenticationController auth;

    NavComponent(this.auth);
}
