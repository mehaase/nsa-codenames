import 'package:angular/angular.dart';

import 'package:nsa_codenames/model/codename-result.dart';

@Component(
    selector: 'codename-result',
    templateUrl: 'packages/nsa_codenames/component/codename-result.html',
    useShadowDom: false
)
class CodenameResultComponent {
    @NgOneWay('codename')
    CodenameResult codename;
}
