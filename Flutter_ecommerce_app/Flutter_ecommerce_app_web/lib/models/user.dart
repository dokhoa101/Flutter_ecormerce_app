class User {
  String? sId;
  String? name;
  String? email;
  String? password;
  String? imgUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;

  User({
    this.sId,
    this.name,
    this.email,
    this.password,
    this.imgUrl,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  User.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    email = json['email'];
    password = json['password'];
    imgUrl = json['imgUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['email'] = email;
    data['password'] = password;
    data['imgUrl'] = imgUrl;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
