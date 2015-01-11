import 'package:nsa_codenames/model/image.dart';
import 'package:nsa_codenames/model/reference.dart';

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
