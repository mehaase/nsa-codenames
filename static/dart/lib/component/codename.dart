import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:nsa_codenames/authentication.dart';
import 'package:nsa_codenames/model/codename.dart';
import 'package:nsa_codenames/model/image.dart';
import 'package:nsa_codenames/model/reference.dart';

@Component(
    selector: 'codename',
    templateUrl: '/static/dart/web/packages/nsa_codenames/component/codename.html',
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
