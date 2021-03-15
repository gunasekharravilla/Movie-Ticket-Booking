import 'dart:math';

import 'package:built_collection/src/list.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/streams/value_stream.dart';
import 'package:tuple/tuple.dart';

import '../../domain/model/city.dart';
import '../../domain/repository/city_repository.dart';
import '../../utils/optional.dart';
import '../local/user_local.dart';
import '../local/user_local_source.dart';

// ignore_for_file: deprecated_member_use_from_same_package

class CityRepositoryImpl implements CityRepository {
  static const _city_key = 'com.chandu.cscinemas.city';

  static final _allCities = <City>[
    City((b) => b..name = CityRepository.nationwide),
    City(
      (b) => b
        ..name = 'Tirupati'
        ..location = (b.location
          ..latitude = 13.6390501
          ..longitude = 79.4230402),
    ),
    City(
      (b) => b
        ..name = 'Pileru'
        ..location = (b.location
          ..latitude = 13.651179
          ..longitude = 79.018310),
    ),
    City(
      (b) => b
        ..name = 'Nagari'
        ..location = (b.location
          ..latitude = 13.325125
          ..longitude = 79.587711),
    ),
  ].build();

  static final _allCitiesByName = {
    for (final city in _allCities) city.name: city
  };

  final RxSharedPreferences _preferences;
  final ValueConnectableStream<City> _selectedCity$;

  CityRepositoryImpl(this._preferences, UserLocalSource userLocalSource)
      : _selectedCity$ = _buildSelectedCity(_preferences, userLocalSource)
          ..connect();

  @override
  BuiltList<City> get allCities => _allCities;

  @override
  Future<void> change(City city) =>
      _preferences.setString(_city_key, city.name);

  @override
  ValueStream<City> get selectedCity$ => _selectedCity$;

  static ValueConnectableStream<City> _buildSelectedCity(
    RxSharedPreferences prefs,
    UserLocalSource userLocalSource,
  ) {
    userLocalSource.user$
        .map((user) => Optional.of(user?.location))
        .whereType<Some<LocationLocal>>()
        .map((location) => _findNearestCityFrom(location.value).name)
        .switchMap((name) => prefs.setString(_city_key, name).asStream())
        .listen(null);

    return prefs
        .getStringStream(_city_key)
        .map((name) => _allCitiesByName[name] ?? _allCities.first)
        .publishValueSeeded(_allCities.first);
  }

  static City _findNearestCityFrom(LocationLocal location) {
    return _allCities
        .skip(1)
        .map(
          (city) => Tuple2(
            city,
            _distanceBetween(
              location.latitude,
              location.longitude,
              city.location!.latitude,
              city.location!.longitude,
            ),
          ),
        )
        .reduce((acc, element) => element.item2 < acc.item2 ? element : acc)
        .item1;
  }
}

double _toRadians(double degrees) => degrees * pi / 180;

double _distanceBetween(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final earthRadius = 6371000; //meters
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}
