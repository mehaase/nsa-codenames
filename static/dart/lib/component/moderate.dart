import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:nsa_codenames/authentication.dart';
import 'package:nsa_codenames/component/title.dart';
import 'package:nsa_codenames/model/moderate-item.dart';

@Component(
    selector: 'moderate',
    templateUrl: 'packages/nsa_codenames/component/moderate.html',
    useShadowDom: false
)
class ModerateComponent {
    AuthenticationController auth;
    List<ModerateItem> moderateItems;
    TitleService ts;

    ModerateComponent(this.auth, this.ts) {
        this.ts.title = 'Moderate';
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
