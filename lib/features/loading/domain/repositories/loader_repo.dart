import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rides365/core/network/failure.dart';

abstract class LoaderRepository {
  Future<Either<Failure, dynamic>> updateUserLocation(
      {required LatLng currentLocation});
}
