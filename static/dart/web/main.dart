import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:bootjack/bootjack.dart';
import 'package:dquery/dquery.dart';
import 'package:logging/logging.dart';

import 'package:nsa_codenames/authentication.dart';
import 'package:nsa_codenames/component/about.dart';
import 'package:nsa_codenames/component/add-codename.dart';
import 'package:nsa_codenames/component/codename.dart';
import 'package:nsa_codenames/component/codename-result.dart';
import 'package:nsa_codenames/component/index.dart';
import 'package:nsa_codenames/component/home.dart';
import 'package:nsa_codenames/component/login.dart';
import 'package:nsa_codenames/component/markdown.dart';
import 'package:nsa_codenames/component/moderate.dart';
import 'package:nsa_codenames/component/nav.dart';
import 'package:nsa_codenames/component/search.dart';
import 'package:nsa_codenames/component/title.dart';
import 'package:nsa_codenames/decorator/current-route.dart';
import 'package:nsa_codenames/router.dart';

/// A URI policy that accepts all URIs.
///
/// This is used in conjunction with the NodeValidator to allow external
/// links.
class WildcardUriPolicy implements UriPolicy {
    bool allowsUri(uri) => true;
}

/// Main application component.
class NsaCodenamesApplication extends Module {
    NsaCodenamesApplication({Level logLevel: Level.OFF}) {
        Logger.root.level = logLevel;
        Logger.root.onRecord.listen((LogRecord rec) {
            print('${rec.time} [${rec.level.name}] ${rec.message}');
        });

        NodeValidatorBuilder nodeValidator = new NodeValidatorBuilder.common()
            ..allowHtml5()
            ..allowNavigation(new WildcardUriPolicy());

        bind(AboutComponent);
        bind(AddCodenameComponent);
        bind(AuthenticationController);
        bind(CodenameComponent);
        bind(CodenameResultComponent);
        bind(CurrentRoute);
        bind(IndexComponent);
        bind(HomeComponent);
        bind(LoginComponent);
        bind(MarkdownComponent);
        bind(ModerateComponent);
        bind(NavComponent);
        bind(NodeValidator, toValue: nodeValidator);
        bind(RouteInitializerFn,
             toImplementation: NsaCodenamesRouteInitializer);
        bind(SearchComponent);
        bind(TitleComponent);
        bind(TitleService);
    }
}

/// Application entry point.
void main() {
    // Register Bootjack components.
    Collapse.use();
    Dropdown.use();
    Transition.use();

    // Create main application.
    applicationFactory()
        .addModule(new NsaCodenamesApplication())
        .run();
}
