import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:bootjack/bootjack.dart';
import 'package:dquery/dquery.dart';

@Injectable()
class MyRouteInitializer implements Function {
    AuthenticationController auth;

    MyRouteInitializer(this.auth);

    void call(Router router, RouteViewFactory views) {
        views.configure({
            'about': ngRoute(
                path: '/about',
                view: '/static/html/views/about.html'
            ),
            'codename': ngRoute(
                defaultRoute: true,
                path: '/:slug',
                view: '/static/html/views/codename.html',
                preEnter: (e) {
                    if (e.parameters['slug'] == null) {
                        router.go('home', {});
                    }
                }
            ),
            'add-codename': ngRoute(
                path: '/add-codename',
                view: '/static/html/views/add-codename.html',
                preEnter: auth.requireLogin
            ),
            'home': ngRoute(
                path: '/home',
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
            'moderate': ngRoute(
                path: '/moderate',
                view: '/static/html/views/moderate.html',
                preEnter: auth.requireLogin
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
        bind(ModerateComponent);
        bind(NavComponent);
        bind(NodeValidator, toValue: nodeValidator);
        bind(RouteInitializerFn, toImplementation: MyRouteInitializer);
        bind(SearchComponent);
    }
}

@Component(
    selector: 'about',
    templateUrl: 'packages/about.html',
    useShadowDom: false
)
class AboutComponent {
    AuthenticationController auth;

    bool editable;
    String markdown;
    DateTime updated;

    AboutComponent(this.auth) {
        this.editable = this.auth.isAdmin();

        HttpRequest.request('/api/content/about', requestHeaders:{'Accept': 'application/json'}).then((request) {
            Map json = JSON.decode(request.response);
            this.markdown = json['markdown'];
            // Dart uses milliseconds instead of seconds:
            int timestamp = json['updated'] * 1000;
            this.updated = new DateTime.fromMillisecondsSinceEpoch(timestamp);
        });
    }

    Future save() {
        return HttpRequest.request(
            '/api/content/about',
            method: 'PUT',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
            sendData: JSON.encode({'markdown': this.markdown})
        ).then((request) {
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
            '/api/codename/',
            method: 'POST',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
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

@Injectable()
class AuthenticationController {
    User currentUser;
    String token;

    Router _router;
    bool _redirect;

    Completer<bool> _loggedInCompleter;
    Completer<bool> _notLoggedInCompleter;

    AuthenticationController(Router router) {
        this._router = router;

        this._loggedInCompleter = new Completer<bool>();
        this._notLoggedInCompleter = new Completer<bool>();
        this._loggedInCompleter.future.then((isLoggedIn) {
            this._notLoggedInCompleter.complete(!isLoggedIn);
        });

        if (window.localStorage.containsKey('token')) {
            this.logIn(window.localStorage['token'], redirect: false);
        } else {
            this._loggedInCompleter.complete(false);
        }
    }

    void requireLogin(RoutePreEnterEvent e) {
        e.allowEnter(this._loggedInCompleter.future);

        this._loggedInCompleter.future.then((result) {
            if (!result) {
                this._router.go('login', {});
            }
        });
    }

    void requireNoLogin(RoutePreEnterEvent e) {
        e.allowEnter(this._notLoggedInCompleter.future);

        this._notLoggedInCompleter.future.then((result) {
            if (!result) {
                this._router.go('home', {});
            }
        });
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

        HttpRequest.request(
            '/api/user/whoami',
            requestHeaders: {'Auth': this.token, 'Accept': 'application/json'}
        ).then(this.continueLogin)
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

            if (!this._loggedInCompleter.isCompleted) {
                this._loggedInCompleter.complete(true);
            }
        } else {
            window.localStorage.remove('token');

            if (!this._loggedInCompleter.isCompleted) {
                this._loggedInCompleter.complete(false);
            }
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
           newReferenceUrl,
           status='';

    bool disableCarouselButtons = false,
         disableDeleteButton = false,
         editable = false,
         showAddReferenceForm = false,
         showHud = false,
         showProgress = false,
         showSpinner = false;

    int currentImageIndex = 0;

    CodenameComponent(this.auth, this.rp, this.router) {
        this.editable = this.auth.isAdmin();
        this.codenameUrl = '/api/codename/' + this.rp.parameters['slug'];

        HttpRequest.request(
            this.codenameUrl,
            method: 'GET',
            requestHeaders: {'Auth': this.auth.token != null ? this.auth.token :  '', 'Accept': 'application/json'}
        ).then((request) {
            Map json = JSON.decode(request.response);
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
                requestHeaders: {'Auth': this.auth.token, 'Accept': 'application/json'}
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
            requestHeaders: {'Auth': this.auth.token, 'Accept': 'application/json'}
        ).then((request) {
            codename.references.removeAt(index);
        });
    }

    Future saveCodename() {
        Map codenameJson = {
            'description': codename.description,
            'summary': codename.summary
        };

        return HttpRequest.request(
            this.codenameUrl,
            method: 'PUT',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
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
            requestHeaders: {'Auth': this.auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
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

    void vote() {
        if (this.auth.token == null) {
            window.alert('Please log in to vote on artwork.');
            return;
        }

        Image currentImage = this.codename.images[this.currentImageIndex];
        String method = currentImage.voted ? 'DELETE' : 'POST';

        this.disableCarouselButtons = true;

        return HttpRequest.request(
            currentImage.url + '/vote',
            method: method,
            requestHeaders: {'Auth': auth.token, 'Accept': 'application/json'}
        ).then((request) {
            Map json = JSON.decode(request.response);
            currentImage.voted = json['voted'];
            currentImage.votes = json['votes'];
        }).whenComplete(() {
            this.disableCarouselButtons = false;
        });
    }

    void selectFile() {
        if (this.auth.token == null) {
            window.alert('Please log in to upload artwork.');
            return;
        }

        InputElement fileEl = querySelector('input[type=file]');

        if (fileEl != null) {
            fileEl.click();
        }
    }

    void upload(Event e) {
        if (e.target.files.length == 0) {
            return;
        }

        Element progress = querySelector('div.progress-bar');
        String url = '/api/codename/' + this.codename.slug + '/images';
        Map headers = {'Auth': auth.token, 'Content-Type': 'image/png'};

        this.status = '';
        this.disableCarouselButtons = true;
        this.showHud = true;
        this.showProgress = true;

        progress.style.width = '0%';

        HttpRequest request = new HttpRequest();
        request.open('POST', url);
        request.setRequestHeader('Accept', 'application/json');
        request.setRequestHeader('Auth', auth.token);
        request.setRequestHeader('Content-Type', 'image/png');

        request.onProgress.listen((event) {
            if (event.lengthComputable) {
                double percentComplete = (event.loaded / event.total) * 100;
                progress.style.width = percentComplete.toInt().toString() + '%';
            }
        });

        request.onLoad.listen((event) {
            Map<String,String> response = JSON.decode(event.target.response);

            if (event.target.status == 200) {
                Image image = new Image(response);

                if (response['replace'] && this.codename.images.length > 0) {
                    this.codename.images[0] = image;
                } else {
                    this.codename.images.add(image);
                    this.currentImageIndex = this.codename.images.length - 1;
                }
            } else {
                this.status = response['message'];
                Element warning = querySelector('div.alert');

                if (warning != null) {
                    warning.scrollIntoView();
                }
            }

            new Timer(new Duration(seconds: 1), () {
                this.disableCarouselButtons = false;
                this.showHud = false;
                this.showProgress = false;
            });
        });

        request.send(e.target.files[0]);
    }

    void forward() {
        this.currentImageIndex = (this.currentImageIndex + 1) %
                                 this.codename.images.length;
    }

    void backward() {
        int delta = this.codename.images.length - 1;
        this.currentImageIndex = (this.currentImageIndex + delta) %
                                 this.codename.images.length;
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

        HttpRequest.request('/api/content/home', requestHeaders:{'Accept': 'application/json'}).then((request) {
            Map json = JSON.decode(request.response);
            this.markdown = json['markdown'];
        });
    }

    Future save() {
        return HttpRequest.request(
            '/api/content/home',
            method: 'PUT',
            requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
            sendData: JSON.encode({'markdown': this.markdown})
        );
    }
}

class Image {
    String contributor, thumbUrl, url;
    int votes;
    bool approved, voted;

    Image(Map json) {
        this.contributor = json['contributor']['username'];
        this.thumbUrl = json['thumbUrl'];
        this.url = json['url'];
        this.approved = json['approved'];
        this.voted = json['voted'];
        this.votes = json['votes'];
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

        HttpRequest.request('/api/codename/', requestHeaders:{'Accept': 'application/json'}).then((request) {
            Map json = JSON.decode(request.response);

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
    String apiUrl = '/api/authenticate/twitter/';

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
        HttpRequest.request(this.apiUrl, requestHeaders:{'Accept': 'application/json'}).then(this.continueTwitter);
        this.showSpinner = true;
    }

    void continueTwitter(String request) {
        Map response = JSON.decode(request.response);

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
            'Accept': 'application/json',
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
                this.disableButtons = false;
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
            '/api/user/whoami',
            method: 'POST',
            requestHeaders: {'Auth': this.auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
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

@Component(
    selector: 'moderate',
    templateUrl: '/static/html/components/moderate.html',
    useShadowDom: false
)
class ModerateComponent {
    AuthenticationController auth;
    List<ModerateItem> moderateItems;

    ModerateComponent(this.auth) {
        this.moderateItems = new List<ModerateItem>();

        HttpRequest.request('/api/codename/approval', requestHeaders:{'Accept': 'application/json', 'Auth': auth.token}).then((request) {
            Map json = JSON.decode(request.response);

            for (Map moderateJson in json['approvals']) {
                this.moderateItems.add(new ModerateItem(moderateJson));
            }
        });
    }

    void approve(int index) {

        ModerateItem moderateItem = this.moderateItems[index];
        String confirmation = "Are you sure you want to approve this artwork"
                            + " for '"
                            + moderateItem.codename
                            + "'?";

        if (window.confirm(confirmation)) {
            HttpRequest.request(
                moderateItem.approveUrl,
                method: 'POST',
                requestHeaders: {'Auth': auth.token, 'Content-Type': 'application/json', 'Accept': 'application/json'}
            ).then((request) {
                this.moderateItems.removeAt(index);
            });
        }
    }

    void delete(int index) {
        ModerateItem moderateItem = this.moderateItems[index];
        String confirmation = "Are you sure you want to delete this artwork"
                            + " for '"
                            + moderateItem.codename
                            + "'?";

        if (window.confirm(confirmation)) {
            HttpRequest.request(
                moderateItem.deleteUrl,
                method: 'DELETE',
                requestHeaders: {'Auth': this.auth.token, 'Accept': 'application/json'}
            ).then((request) {
                this.moderateItems.removeAt(index);
            });
        }
    }
}

class ModerateItem {
    String approveUrl, codename, codenameSlug, codenameUrl,
           contributor, deleteUrl, imageUrl;

    ModerateItem(Map json) {
        this.approveUrl = json['approveUrl'];
        this.codename = json['codename']['name'];
        this.codenameSlug = json['codename']['slug'];
        this.codenameUrl = json['codename']['url'];
        this.contributor = json['contributor']['username'];
        this.deleteUrl = json['deleteUrl'];
        this.imageUrl = json['imageUrl'];
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
        results = new List<CodenameResult>();
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
            String url = '/api/codename/search?q=' + this.query;
            HttpRequest.request(url, requestHeaders:{'Accept': 'application/json'}).then(this.onDataLoaded);
            this.showSpinner = true;
        }
    }

    void onDataLoaded(String request) {
        this.showSpinner = false;
        Map searchResults = JSON.decode(request.response);
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