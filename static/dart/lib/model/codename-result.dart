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
