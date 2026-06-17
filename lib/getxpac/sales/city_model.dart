class City {
  final int id;
  final String name;
  final String stateId;
  final String stateName;

  City({
    required this.id,
    required this.name,
    required this.stateId,
    required this.stateName,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
      stateId: json['state_id'],
      stateName: json['state']['name'],
    );
  }
}
