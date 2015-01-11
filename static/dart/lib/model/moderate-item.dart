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
