class Reference {
    String annotation, externalUrl, url;

    Reference(Map json) {
        this.annotation = json['annotation'];
        this.externalUrl = json['externalUrl'];
        this.url = json['url'];
    }
}
