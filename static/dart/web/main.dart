import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:bootjack/bootjack.dart';
import 'package:dquery/dquery.dart';

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
import 'package:nsa_codenames/decorator/current-route.dart';
import 'package:nsa_codenames/router.dart';

class NsaCodenames extends Module {
    NsaCodenames() {
        NodeValidatorBuilder nodeValidator = new NodeValidatorBuilder.common()
            ..allowHtml5()
            ..allowElement('a', attributes: ['href']);

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
        bind(RouteInitializerFn, toImplementation: MyRouteInitializer);
        bind(SearchComponent);
    }
}

void main() {
    // Register Bootjack components.
    Collapse.use();
    Dropdown.use();
    Transition.use();

    // Create main application.
    applicationFactory()
        .addModule(new NsaCodenames())
        .run();
}
