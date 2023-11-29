import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:capstone/firebase/map_list.dart';
//import 'package:location/location.dart';
import 'package:capstone/cycle/cycle.dart';
import 'package:capstone/cycle/cycle_repository.dart';
import 'package:capstone/evcar/ev.dart';
import 'package:capstone/evcar/ev_repository.dart';
import 'package:capstone/accommodation/accommodation.dart';
import 'package:capstone/accommodation/accommodation_repository.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  TextEditingController _controller = TextEditingController();
  // TextField에 입력된 값을 가져오거나 TextField에 입력된 값이 변경될 때 사용

  double latitude = 37.553836;
  double longitude = 126.969652;

  Set<Marker> markers = {};

  bool areMarkersVisible = false;
  bool areBikeMarkersVisible = false; // 새로 추가된 부분
  bool areEvMarkerVisible = false;
  bool areAccMarkersVisible = false;

  @override
  void initState() {
    super.initState();
    // getCurrentLocation().then((position) {
    //   setState(() {
    //     latitude = position.latitude;
    //     longitude = position.longitude;
    //   });
    // });
    loadMarkers();
    loadEvMarkers();
    //loadMarkersFromFirestore();
    loadCycleMarkers();
    loadAccMarkers();
  }



  Future<void> loadAccMarkers() async {
    try {
      List<Accommodation>? accs = await AccommodationRepository().loadAccs();
      if (accs != null && accs.isNotEmpty) {
        Set<Marker> newMarkers = accs.map((acc) {
          final BitmapDescriptor markerIcon = _getMarkerIconForAcc();
          return Marker(
            markerId: MarkerId('acc${acc.contentid}'),
            position:
            LatLng(double.parse(acc.mapy), double.parse(acc.mapx)),
            infoWindow: InfoWindow(title: acc.title),
            icon: markerIcon,
            onTap: () {
              _onMarkerTapped(MarkerId('acc${acc.contentid}'));
            },
          );
        }).toSet();

        setState(() {
          if(!areAccMarkersVisible) markers.clear();
          markers.addAll(newMarkers);
        });
      }
    } catch(e) {
      print('Error loading accommodation list: $e');
    }
  }

  Future<void> loadCycleMarkers() async {
    try {
      List<Cycle>? cycles = await CycleRepository().loadCycles();
      if (cycles != null && cycles.isNotEmpty) {
        Set<Marker> newMarkers = cycles.map((cycle) {
          final BitmapDescriptor markerIcon = _getMarkerIconForCycle();
          return Marker(
            markerId: MarkerId('bike${cycle.rentId}'),
            position:
                LatLng(double.parse(cycle.staLat), double.parse(cycle.staLong)),
            infoWindow: InfoWindow(title: cycle.rentNm),
            icon: markerIcon,
          );
        }).toSet();

        setState(() {
          if (!areBikeMarkersVisible) markers.clear();
          markers.addAll(newMarkers);
        });
      }
    } catch (e) {
      print('Error loading bike stations: $e');
      // 적절한 오류 처리 추가
    }
  }

  Future<void> loadMarkers() async {
    // loadMarkersFromFirestore() 내용을 여기로 옮김
    List<Map<String, dynamic>> cafes = await FireService().getFireModels();
    Set<Marker> newMarkers = cafes.map((cafe) {
      final BitmapDescriptor markerIcon = _getMarkerIcon();
      return Marker(
        markerId: MarkerId('cafe${cafe['shop'].toString()}'),
        position: LatLng(
            cafe['latitude'] as double, cafe['longitude'] as double),
        infoWindow: InfoWindow(title: cafe['shop'].toString()),
        icon: markerIcon,
      );
    }).toSet();

    setState(() {
      if (!areMarkersVisible) markers.clear();
      markers.addAll(newMarkers);
    });
  }

  BitmapDescriptor _getMarkerIcon() {
    // 적절한 조건에 따라 다른 색상의 아이콘을 반환
    if (areMarkersVisible) {
      return BitmapDescriptor.defaultMarker;
      //return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      return BitmapDescriptor.fromBytes(Uint8List(0));
      //return BitmapDescriptor.defaultMarker; // 수정 후 코드
      //return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  BitmapDescriptor _getMarkerIconForAcc() {
    // 적절한 조건에 따라 다른 색상의 아이콘을 반환
    if (areAccMarkersVisible) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.fromBytes(Uint8List(0));

      //return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  BitmapDescriptor _getMarkerIconForCycle() {
    // 적절한 조건에 따라 다른 색상의 아이콘을 반환
    if (areBikeMarkersVisible) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      return BitmapDescriptor.fromBytes(Uint8List(0));
      //return BitmapDescriptor.defaultMarker; // 수정 후 코드
      //return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _toggleMarkers() async {
    setState(() {
      areMarkersVisible = !areMarkersVisible;
      if (areMarkersVisible == false) {
        markers.removeWhere((marker) => marker.markerId.value.startsWith("cafe"));
      } else {
        loadMarkers();
      }
    });
  }

  Future<void> _toggleBikeMarkers() async {
    setState(() {
      areBikeMarkersVisible = !areBikeMarkersVisible;
      if (!areBikeMarkersVisible) {
        markers.removeWhere((marker) => marker.markerId.value.startsWith("bike"));
      } else {
        loadCycleMarkers();
      }
    });
  }

  Future<void> loadEvMarkers() async {
    try {
      List<Ev>? evs = await EvRepository().loadEvs();
      if (evs != null && evs.isNotEmpty) {
        Set<Marker> newMarkers = evs.map((ev) {
          final BitmapDescriptor markerIcon = _getMarkerIconForEv();
          return Marker(
            markerId: MarkerId('ev${ev.addr}'),
            position:
              LatLng(double.parse(ev.lat), double.parse(ev.longi)),
            infoWindow: InfoWindow(title: ev.csNm),
            icon: markerIcon,
          );
        }).toSet();

        setState(() {
         if(!areEvMarkerVisible) markers.clear();
         markers.addAll(newMarkers);
        });
      }
    } catch(e) {
      print('Error loading ev list: $e');
    }
  }

  BitmapDescriptor _getMarkerIconForEv() {
    // 적절한 조건에 따라 다른 색상의 아이콘을 반환
    if (areEvMarkerVisible) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else {
      return BitmapDescriptor.fromBytes(Uint8List(0));
    }
  }

  Future<void> _toggleAccMarkers() async {
    setState(() {
      areAccMarkersVisible = !areAccMarkersVisible;
      if (!areAccMarkersVisible) {
        markers.removeWhere((marker) => marker.markerId.value.startsWith("acc"));
      } else {
        loadAccMarkers();
      }
    });
  }

  Future<void> _toggleEvMarkers() async {
    setState(() {
      areEvMarkerVisible = !areEvMarkerVisible;
      if (!areEvMarkerVisible) {
        markers.removeWhere((marker) => marker.markerId.value.startsWith("ev"));
      } else {
        loadEvMarkers();
      }
    });
  }


  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되었는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 비활성화된 경우 처리
      // 사용자에게 위치 서비스를 활성화하라는 메시지를 보여줄 수 있습니다.
      print("위치서비스가 비활성화되어있습니다.");
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 위치 권한이 거부된 경우 권한 요청
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 사용자가 위치 권한을 거부한 경우 처리
        // 사용자에게 메시지를 표시하거나 정보를 제공할 수 있습니다.
        print("위치 권한을 거부하였습니다.");
      }
    }

    Position position = await Geolocator.getCurrentPosition();

    print("Received location: ${position.latitude}, ${position.longitude}");

    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId('userLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );
    });

    print("Set new location: $latitude, $longitude");

    mapController.moveCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
    return position;
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    //target: LatLng(37.553836, 126.969652),
    target: LatLng(37.503430, 126.957077),
    zoom: 15,
  );

  Future<void> _onMarkerTapped(MarkerId markerId) async {
    if (markerId.value.startsWith('acc')) {
      String contentid = markerId.value.substring(3);
      Accommodation? tappedAccommodation;
      List<Accommodation?> accommodations = await AccommodationRepository().getAccommodationDetails(contentid);
      if (accommodations.isNotEmpty) {
        tappedAccommodation = accommodations.first;
      }
      if (tappedAccommodation != null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tappedAccommodation!.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text('Address: ${tappedAccommodation.add1} ${tappedAccommodation.add2}'),
                    SizedBox(height: 4.0),
                    Text('Tel: ${tappedAccommodation.tel}'),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        // Your favorite icon button action
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite),
                          SizedBox(width: 8.0),
                          Text('Add to Favorites'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // showCupertinoModalPopup(
        //   context: context,
        //   builder: (BuildContext context) {
        //     return CupertinoActionSheet(
        //       title: Column(
        //         children: [
        //           Text(tappedAccommodation!.title!,
        //             style: TextStyle(
        //               fontSize: 20.0,
        //               color: Colors.black,
        //             )
        //           ),
        //           SizedBox(
        //             height: 5,
        //           )
        //         ],
        //       ),
        //       message: Column(
        //         children: [
        //           Text('Address: ${tappedAccommodation.add1} ${tappedAccommodation.add2}',
        //               style: TextStyle(
        //                 fontSize: 15.0,
        //                 color: Colors.black,
        //               )),
        //           SizedBox(
        //             height: 20,
        //           ),
        //           Text('Tel: ${tappedAccommodation.tel}',
        //               style: TextStyle(
        //                 fontSize: 15.0,
        //                 color: Colors.black,
        //               )),
        //         ],
        //       ),
        //       actions: [
        //         CupertinoActionSheetAction(
        //           onPressed: () {
        //             // 즐겨찾기 기능 추가
        //           },
        //           child: Row(
        //             mainAxisAlignment: MainAxisAlignment.center,
        //             children: [
        //               //Icon(Icons.star),
        //               //SizedBox(width: 8),
        //               Text('Add to Favorites'),
        //             ],
        //           ),
        //         ),
        //         // CupertinoActionSheetAction(
        //         //   onPressed: () {
        //         //     Navigator.pop(context); // 팝업 닫기
        //         //   },
        //         //   child: Text('Close'),
        //         // ),
        //         // CupertinoActionSheetAction(
        //         //   onPressed: () {
        //         //     Navigator.pop(context);
        //         //   },
        //         //   child: Text('Close'),
        //         // ),
        //       ],
        //     );
        //   },
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:16),
      // child: Center(
      child: Column(
        //crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Center(
            child: Column(
              children: [
                // TextField(
                //   controller: _controller,
                //   decoration: InputDecoration(
                //     hintText: 'Search...',
                //     suffixIcon: IconButton(
                //       icon: Icon(Icons.search),
                //       onPressed: () {
                //         // Perform search based on _controller.text
                //         // You can call a search function here
                //       },
                //     ),
                //   ),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        print("Button Pressed");

                        _toggleAccMarkers();
                      },
                      child: Image(
                        image: AssetImage('assets/accommodation.png'),
                        width: 40.0,
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        print("Button Pressed");

                        _toggleMarkers();
                        // setState(() {
                        //   areMarkersVisible =
                        //       !areMarkersVisible; // Toggle visibility state
                        // });
                        // loadMarkers();
                        //loadMarkersFromFirestore(); // Load markers based on the new visibility state
                      },
                      child: Image(
                        image: AssetImage('assets/food.png'),
                        width: 40.0,
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        print("Button Pressed");

                        _toggleBikeMarkers();
                      },
                      child: Image(
                        image: AssetImage('assets/bike.png'),
                        width: 40.0,
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                         _toggleEvMarkers();
                        // setState(() {
                        //   areEvMarkerVisible = !areEvMarkerVisible;
                        // });
                        // loadEvMarkers();
                      },
                      child: Image(
                        image: AssetImage('assets/electriccar.png'),
                        width: 40.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 13,
                ),
                Center(
                  child: SizedBox(
                    height: 405.0,
                    width: MediaQuery.of(context).size.width - 50,
                    child: GoogleMap(
                        initialCameraPosition: _kGooglePlex,
                        //initialCameraPosition: CameraPosition(target:LatLng(latitude, longitude)),
                        mapType: MapType.normal,
                        markers: Set.from(markers),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onCameraMove: (_) {},
                        onMapCreated: ((controller) async {
                          mapController = controller;
                          // var currentLocation = await getCurrentLocation();
                          // mapController.moveCamera(CameraUpdate.newLatLng(
                          //     LatLng(currentLocation.latitude,
                          //         currentLocation.longitude)));
                          setState(() {});
                        })),
                  ),
                ),
              ],
            ),
          ),
          // Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          //   FloatingActionButton.small(
          //     onPressed: () async {
          //       var gps = await getCurrentLocation();
          //
          //       mapController.moveCamera(CameraUpdate.newLatLng(
          //           LatLng(gps.latitude, gps.longitude)));
          //
          //       // print("FloatingActionButton pressed");
          //       print("Current Location: $gps");
          //       // mapController.moveCamera(
          //       //     CameraUpdate.newLatLng(LatLng(currentLocation.latitude, currentLocation.longitude)));
          //     },
          //     child: Icon(
          //       Icons.my_location,
          //       color: Colors.black,
          //     ),
          //     shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(30)),
          //     backgroundColor: Colors.white,
          //   ),
          //   SizedBox(
          //     width: 15,
          //   )
          // ])
        ],
      ),
    );
  }
}
