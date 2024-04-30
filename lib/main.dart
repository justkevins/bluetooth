import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import "package:intl/intl.dart";
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Device Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BluetoothScanPage(),
    );
  }
}

class BluetoothScanPage extends StatefulWidget {
  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  Map<String, String> deviceRssiMap = {};
  bool isScanning = false;
  final DateFormat f = DateFormat('hh:mm:ss yyyy-MM-dd');
  StreamSubscription? scanSubscription;

  @override
  void initState() {
    super.initState();
    checkPermissionsAndStart();
  }

  Future<void> checkPermissionsAndStart() async {
    var statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    if (statuses.values.any((status) => !status.isGranted)) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Permissions Error"),
          content: Text("Please grant all permissions to continue."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      startScan();
    }
  }

  void startScan() {
    setState(() {
      devicesList.clear();
      isScanning = true;
    });
    flutterBlue.startScan(timeout: Duration(seconds: 60));
    scanSubscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesList.any((device) => device.id == result.device.id)) {
          setState(() {
            devicesList.add(result.device);
            deviceRssiMap[result.device.id.toString()] = "${result.rssi}";
          });
        }
      }
    }, onError: (error) {
      print("Scan failed with error: $error");
    });
  }

  void stopScan() {
    flutterBlue.stopScan();
    scanSubscription?.cancel();
    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Device Scanner"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                var device = devicesList[index];
                var rssi = deviceRssiMap[device.id.toString()];
                var now = f.format(DateTime.now());
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(device.name.isEmpty ? '(unknown device)' : device.name),
                    subtitle: Text('MAC: ${device.id} \nRSSI: $rssi \nTimestamp: $now'),
                    trailing: Icon(Icons.signal_cellular_4_bar, color: Colors.green),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isScanning ? null : startScan,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start Scanning'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: isScanning ? Colors.grey : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isScanning ? stopScan : null,
                  icon: Icon(Icons.stop),
                  label: Text('Stop Scanning'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: isScanning ? Colors.red : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
