import 'package:geocoding/geocoding.dart';

class UserLocationModel {
  final String street;
  final String zipCode;
  final String city;
  final String state;
  final String country;

  UserLocationModel({
    required this.street,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.country,
  });

  factory UserLocationModel.fromPlacemark(Placemark p) {
    return UserLocationModel(
      street: p.street ?? '',
      zipCode: p.postalCode ?? '',
      city: p.locality ?? '',
      state: p.administrativeArea ?? '',
      country: p.country ?? '',
    );
  }

  @override
  String toString() {
    return "$street, $zipCode, $city, $state, $country";
  }
}
