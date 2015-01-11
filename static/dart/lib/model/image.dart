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
