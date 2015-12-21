import 'dart:js';

import 'package:angular/angular.dart';

@Component(
    selector: 'markdown',
    templateUrl: 'packages/nsa_codenames/component/markdown.html',
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

