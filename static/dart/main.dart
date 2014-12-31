import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:bootjack/bootjack.dart';
import 'package:dquery/dquery.dart';

class MyRouteInitializer implements Function {
    AuthenticationController auth;

    MyRouteInitializer(this.auth);

    void call(Router router, RouteViewFactory views) {
        views.configure({
            'about': ngRoute(
                path: '/about',
                view: '/static/html/views/about.html'
            ),
            'add-codename': ngRoute(
                path: '/add-codename',
                view: '/static/html/views/add-codename.html'
            ),
            'codename': ngRoute(
                path: '/cn/:slug',
                view: '/static/html/views/codename.html'
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
            'login': ngRoute(
                path: '/login',
                view: '/static/html/views/login.html',
                preEnter: auth.requireNoLogin
            ),
            'search': ngRoute(
                path: '/search',
                view: '/static/html/views/search.html'
            ),
        });
    }
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
        String currentRoute = element.attributes['current-route'];

        if (router.activePath.isEmpty) {
            return false;
        }

        return currentRoute == router.activePath.first.name;
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
        bind(NavComponent);
        bind(NgRoutingUsePushState,
             toValue: new NgRoutingUsePushState.value(false));
        bind(NodeValidator, toValue: nodeValidator);
        bind(RouteInitializerFn, toImplementation: MyRouteInitializer);
        bind(SearchComponent);
    }
}

@Component(
    selector: 'about',
    templateUrl: '/static/html/components/about.html',
    useShadowDom: false
)
class AboutComponent {
    AuthenticationController auth;

    bool editable;
    String markdown;
    DateTime updated;

    AboutComponent(this.auth) {
        this.editable = this.auth.isAdmin();

        HttpRequest.getString('/content/about').then((response) {
            Map json = JSON.decode(response);
            this.markdown = json['markdown'];
            // Dart uses milliseconds instead of seconds:
            int timestamp = json['updated'] * 1000;
            this.updated = new DateTime.fromMillisecondsSinceEpoch(timestamp);
        });
    }

    void save() {
        return HttpRequest.request(
            '/content/about',
            method: 'PUT',
            requestHeaders: {'auth': auth.token, 'content-type': 'application/json'},
            sendData: JSON.encode({'markdown': this.markdown})
        ).then((response) {
            this.updated = new DateTime.now();
        });
    }
}

@Component(
    selector: 'add-codename',
    templateUrl: '/static/html/components/add-codename.html',
    useShadowDom: false
)
class AddCodenameComponent {
    AuthenticationController auth;
    Router router;

    String name='', error;
    bool disableButtons = false, showSpinner = false;

    AddCodenameComponent(this.auth, this.router);

    void saveCodename() {
        this.error = null;
        this.showSpinner = true;

        HttpRequest.request(
            '/index',
            method: 'POST',
            requestHeaders: {'auth': auth.token, 'content-type': 'application/json'},
            sendData: JSON.encode({'name': this.name})
        ).then((request) {
            var response = JSON.decode(request.response);
            this.router.go('codename', {'slug': response['slug']});
        }).catchError((e) {
            var response = JSON.decode(e.target.responseText);
            this.error = response['message'];
        }).whenComplete(() {
            this.showSpinner = false;
        });
    }
}

class AuthenticationController {
    User currentUser;
    String token;

    Router _router;
    bool _redirect;

    AuthenticationController(Router router) {
        this._router = router;

        if (window.localStorage.containsKey('token')) {
            this.logIn(window.localStorage['token'], redirect: false);
        }
    }

    void requireLogin(RoutePreEnterEvent e) {
        if (!this.isLoggedIn()) {
            e.allowEnter(new Future<bool>.value(false));
            this._router.go('login', {});
        }
    }

    void requireNoLogin(RoutePreEnterEvent e) {
        if (this.isLoggedIn()) {
            e.allowEnter(new Future<bool>.value(false));
        }
    }

    bool isLoggedIn() {
        return currentUser != null;
    }

    bool isAdmin() {
        return isLoggedIn() && currentUser.isAdmin;
    }

    void logIn(String token, {bool redirect: true}) {
        this._redirect = redirect;
        this.token = token;
        window.localStorage['token'] = token;

        HttpRequest req = HttpRequest.request(
            '/user/whoami',
            requestHeaders: {'Auth': this.token}
        );

        req.then(this.continueLogin)
           .catchError((e) => window.localStorage.remove('token'));
    }

    void continueLogin(HttpRequest request) {
        var response = JSON.decode(request.response);

        if (response['id'] != null) {
            this.currentUser = new User();
            this.currentUser.id = response['id'];
            this.currentUser.username = response['username'];
            this.currentUser.imageUrl = response['image_url'];
            this.currentUser.isAdmin = response['is_admin'];
        } else {
            window.localStorage.remove('token');
        }

        if (this._redirect) {
            this._router.go('home', {});
        }
    }

    void logOut() {
        this.currentUser = null;
        this.token = null;
        window.localStorage.remove('token');

        if (this._router.activePath.first.name == 'login') {
            this._router.go('home', {});
        }
    }
}

class User {
    int id;
    String username, imageUrl;
    bool isAdmin = false;
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
    AuthenticationController auth;
    RouteProvider rp;
    Router router;

    @NgOneWay('codename')
    Codename codename;

    String codenameUrl,
           newReferenceAnnotation,
           newReferenceUrl;

    bool disableDeleteButton = false,
         editable = false,
         showAddReferenceForm = false,
         showSpinner = false;

    CodenameComponent(this.auth, this.rp, this.router) {
        this.editable = this.auth.isAdmin();
        this.codenameUrl = '/' + this.rp.parameters['slug'];

        HttpRequest.getString(this.codenameUrl).then((response) {
            Map json = JSON.decode(response);
            this.codename = new Codename(json);
        });
    }

    void deleteCodename() {
        String confirmation = 'Are you sure you want to delete'
                            + ' "${this.codename.name}"?';

        if (window.confirm(confirmation)) {
            this.showSpinner = true;
            disableDeleteButton = true;

            HttpRequest.request(
                this.codenameUrl,
                method: 'DELETE',
                requestHeaders: {'auth': auth.token}
            ).then((request) {
                this.router.go('index', {});
            }).whenComplete(() {
                this.showSpinner = false;
            });
        }
    }

    void deleteReference(index) {
        Reference ref = codename.references[index];

        return HttpRequest.request(
            ref.url,
            method: 'DELETE',
            requestHeaders: {'auth': auth.token}
        ).then((response) {
            codename.references.removeAt(index);
        });
    }

    void saveCodename() {
        Map codenameJson = {
            'description': codename.description,
            'summary': codename.summary
        };

        HttpRequest.request(
            this.codenameUrl,
            method: 'PUT',
            requestHeaders: {'auth': auth.token, 'content-type': 'application/json'},
            sendData: JSON.encode(codenameJson)
        );
    }

    void addReference() {
        Map referenceJson = {
            'url': this.newReferenceUrl,
            'annotation': this.newReferenceAnnotation
        };

        return HttpRequest.request(
            this.codenameUrl + '/references',
            method: 'POST',
            requestHeaders: {'auth': auth.token, 'content-type': 'application/json'},
            sendData: JSON.encode(referenceJson)
        ).then((request) {
            Map json = JSON.decode(request.response);

            codename.references.add(new Reference({
                'url': json['url'],
                'externalUrl': this.newReferenceUrl,
                'annotation': this.newReferenceAnnotation
            }));
        }).whenComplete(() {
            this.newReferenceAnnotation = '';
            this.newReferenceUrl = '';
            this.showAddReferenceForm = false;
        });
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
    AuthenticationController auth;

    NavComponent(AuthenticationController auth) {
        this.auth = auth;
    }
}

@Component(
    selector: 'home',
    templateUrl: '/static/html/components/home.html',
    useShadowDom: false
)
class HomeComponent {
    AuthenticationController auth;

    String markdown;
    bool editable;

    HomeComponent(this.auth) {
        this.editable = this.auth.isAdmin();

        HttpRequest.getString('/content/home').then((response) {
            Map json = JSON.decode(response);
            this.markdown = json['markdown'];
        });
    }

    void save() {
        return HttpRequest.request(
            '/content/home',
            method: 'PUT',
            requestHeaders: {'auth': auth.token, 'content-type': 'application/json'},
            sendData: JSON.encode({'markdown': this.markdown})
        );
    }
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
        this.letters = new List<String>.generate(
            26,
            (int index) => new String.fromCharCode(index + 0x41)
        );

        this.codenamesByInitial = new Map.fromIterable(
            letters,
            key: (item) => item,
            value: (item) => new List<String>()
        );

        HttpRequest.getString('/index').then((response) {
            Map json = JSON.decode(response);

            for (Map codenameJson in json['codenames']) {
                String initial = codenameJson['name'].substring(0, 1)
                                                     .toUpperCase();

                this.codenamesByInitial[initial].add(
                    new CodenameResult(codenameJson)
                );
            }
        });
    }

    void scroll(String letter) {
        var element = querySelector("#" + letter);
        element.scrollIntoView(ScrollAlignment.TOP);
    }
}

@Component(
    selector: 'login',
    templateUrl: '/static/html/components/login.html',
    useShadowDom: false
)
class LoginComponent {
    AuthenticationController auth;

    String redirectUrl, resourceOwnerKey, resourceOwnerSecret, username='';
    String apiUrl = '/authenticate/twitter/';

    bool disableButtons = false;
    bool showPopupWarning = false;
    bool showUsernamePrompt = false;
    bool showSpinner = false;

    Window popup;
    Timer popupTimer;

    LoginComponent(AuthenticationController auth) {
        this.auth = auth;
    }

    void startTwitter() {
        if (this.popup != null) {
            this.popup.close();
            this.popup = null;
        }

        this.disableButtons = true;
        HttpRequest.getString(this.apiUrl).then(this.continueTwitter);
        this.showSpinner = true;
    }

    void continueTwitter(String jsonResponse) {
        Map response = JSON.decode(jsonResponse);

        this.resourceOwnerKey = response['resource_owner_key'];
        this.resourceOwnerSecret = response['resource_owner_secret'];
        this.popup = window.open(
            response['url'],
            'Log In With Twitter',
            'width=600,height=400'
        );

        // If the popup is closed without completing the workflow, then
        // reset the UI.
        this.popupTimer = new Timer.periodic(
            new Duration(milliseconds: 500),
            (event) {
                if (this.popup != null && this.popup.closed) {
                    this.disableButtons = false;
                    this.showSpinner = false;
                    this.popupTimer.cancel();
                }
            }
        );

        // Wait for the workflow to complete, then finish authentication.
        if (this.popup == null) {
            this.showPopupWarning = true;
        } else {
            window.addEventListener('message', (event) {
                if (event.data.substring(0,4) == 'http') {
                    this.popup.close();
                    this.popupTimer.cancel();
                    this.redirectUrl = event.data;
                    finishTwitter();
                }
            });
        }
    }

    void finishTwitter() {
        Map<String,String> postData = {
            'resource_owner_key': this.resourceOwnerKey,
            'resource_owner_secret': this.resourceOwnerSecret,
            'url': this.redirectUrl
        };

        Map<String,String> headers = {
            'Content-Type': 'application/json'
        };

        HttpRequest.request(
            this.apiUrl,
            method: 'POST',
            requestHeaders: headers,
            sendData: JSON.encode(postData)
        ).then((request) {
            Map<String,String> response = JSON.decode(request.response);
            this.showSpinner = false;

            if (response['pick_username']) {
                this.showUsernamePrompt = true;
                this.auth.logIn(response['token'], redirect: false);
            } else {
                this.auth.logIn(response['token'], redirect: true);
            }
        });
    }

    void saveUsername() {
        this.disableButtons = true;
        this.showSpinner = true;

        HttpRequest.request(
            '/user/whoami',
            method: 'POST',
            requestHeaders: {'auth': this.auth.token, 'content-type': 'application/json'},
            sendData: JSON.encode({'username': username})
        ).then((request) {
            this.auth.logIn(this.auth.token, redirect: true);
        }).whenComplete(() {
            this.showSpinner = false;
        });
    }
}

@Component(
    selector: 'markdown',
    templateUrl: '/static/html/components/markdown.html',
    useShadowDom: false
)
class MarkdownComponent implements ScopeAware {
    @NgTwoWay('text')
    String text;

    @NgOneWay('save-handler')
    Function saveHandler;

    @NgOneWay('editable')
    bool editable = false;

    @NgAttr('rows')
    int rows = 20;

    bool editing;
    String html, originalText;
    bool disableButtons = false, showSpinner = false;

    void set scope(Scope scope) {
        scope.watch('text', (v, p) {
            render();
        });
    }

    void render() {
        if (text != null) {
            this.html = context['markdown'].callMethod('toHTML', [this.text]);
        }
    }

    void edit() {
        this.originalText = text;
        this.editing = true;
    }

    void discard() {
        this.text = this.originalText;
        this.originalText = null;
        this.editing = false;
    }

    void save() {
        this.disableButtons = true;
        this.showSpinner = true;

        saveHandler().whenComplete(() {
            this.disableButtons = false;
            this.showSpinner = false;
            this.editing = false;
        });
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
    bool showSpinner;

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
        if (query.trim() != '') {
            String url = '/search?q=' + this.query;
            HttpRequest.getString(url).then(this.onDataLoaded);
            this.showSpinner = true;
        }
    }

    void onDataLoaded(String response) {
        this.showSpinner = false;
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
    // Register Bootjack components.
    Collapse.use();
    Dropdown.use();
    Transition.use();

    // Create main application.
    applicationFactory()
        .addModule(new NsaCodenamesAppModule())
        .run();
}
