import 'dart:convert';
import 'package:ble_protocol/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ProtocolTest extends StatefulWidget {
  const ProtocolTest({Key key}) : super(key: key);

  @override
  State<ProtocolTest> createState() => _ProtocolTestState();
}

class _ProtocolTestState extends State<ProtocolTest> {

  List<List<int>> cmds = [
    [0xAA, 0x55, 0x04, 0xB1, 0x00, 0x00, 0xB5]
  ];

  List<int> rr_values = [];
  List<BluetoothCharacteristic> notify = [];

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  final List<BluetoothDevice> devicesList = [];
  BluetoothDevice connectedDevice;

  List<BluetoothService> services;

  final Map<Guid, List<int>> readValues = {};

  final writeController = TextEditingController();

  addDeviceToList(final BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      setState(() {
        devicesList.add(device);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: connectedDevice == null ? const Text("iF-H-D3 Protocol") : const Text("RR Intervals"),
      ),
      body: buildView(),
    );
  }

  ListView buildConnectDeviceView() {
    List<Container> containers = [];

    for (BluetoothService service in services) {
      print("protocol_test.buildConnectDeviceView service: ${service.uuid}");
      List<Widget> characteristicsWidget = [];
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.value.listen((value) {
          if (value.length >= 14) {
            if (value[10]==8) {
              int rr = int.parse(
                  value[13].toRadixString(16) + value[12].toRadixString(16),
                  radix: 16) * 2;
              rr_values.add(rr);
            }
          }
        });
        // characteristicsWidget.add(
        //   Align(
        //     alignment: Alignment.centerLeft,
        //     child: Column(
        //       children: <Widget>[
        //         Row(
        //           children: <Widget>[
        //             Text(characteristic.uuid.toString(),
        //                 style: const TextStyle(fontWeight: FontWeight.bold)),
        //           ],
        //         ),
        //         Row(
        //           children: <Widget>[
        //             ...buildReadWriteNotifyButton(characteristic),
        //           ],
        //         ),
        //         Row(
        //           children: <Widget>[
        //             Text('Read value1: ${readValues[characteristic.uuid]}'),
        //           ],
        //         ),
        //         const Divider(),
        //       ],
        //     ),
        //   ),
        // );
      }
      containers.add(
        Container(
          child: ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  Future<void> connectAndGetReadings() async {

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.value.listen((value) {
          if (value.length >= 14) {
            if (value[10]==8) {
              int rr = int.parse(
                  value[13].toRadixString(16) + value[12].toRadixString(16),
                  radix: 16) * 2;
              rr_values.add(rr);
              setState(() {

              });
              print("protocol_test.connectAndGetReadings rr_values: ${rr_values.toString()}");
            }
          }
        });
        if (characteristic.properties.read) {

        }
        if (characteristic.properties.notify &&
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129600" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129601" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129602" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129603" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129604" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129605" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129606" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129607") {
            notify.add(characteristic);
        }
        if (characteristic.properties.write &&
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129600" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129601" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129602" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129603" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129604" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129605" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129606" ||
            characteristic.uuid.toString().toUpperCase() == "D44BC439-ABFD-45A2-B575-925416129607") {
          Future.delayed(const Duration(milliseconds: 2000), () async {
            for(int i = 0; i < cmds.length; i++) {
              await characteristic.write(cmds[i]);
            }
          });

          for(var n in notify) {
            characteristic.value.listen((value) {
              readValues[characteristic.uuid] = value;
            });
            await n.setNotifyValue(true);
          }
        }
      }
    }
  }

  ListView buildListViewOfDevices() {
    List<SizedBox> containers = [];
    for (BluetoothDevice device in devicesList) {
      if (device.name.toLowerCase().startsWith("if")) {
        containers.add(
          SizedBox(
            height: 50,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(device.name == '' ? '(unknown device)' : device.name),
                      Text(device.id.toString()),
                    ],
                  ),
                ),
                MaterialButton(
                  height: 50.0,
                  minWidth: 150.0,
                  color: Colors.white,
                  textColor: Colors.green,
                  splashColor: Theme.of(context).primaryColor,
                  child: const Text(
                    "Connect",
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    flutterBlue.stopScan();
                    try {
                      await device.connect(autoConnect: false);
                    } catch (e) {
                      if (e.code != 'already_connected') {
                        showToast(
                            "Device is already connected to this phone or another");
                      } else {
                        showToast("Error occurred: ${e.toString()}");
                      }
                    } finally {
                      services = await device.discoverServices();
                    }
                    setState(() {
                      connectedDevice = device;
                      showToast("Device connected successfully");
                    });
                    await connectAndGetReadings();
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  Widget buildView() {
    if (connectedDevice != null) {
      String text = "";
      for (var num in rr_values) {
        text += num.toString() + " ";
      }
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            Text(text, style: const TextStyle(
                color: Colors.black,
                fontSize: 12
            ),)
          ]
        )
      );
    }
    return buildListViewOfDevices();
  }

  @override
  void initState() {
    super.initState();
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        addDeviceToList(device);
      }
    });
    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        addDeviceToList(result.device);
      }
    });
    flutterBlue.startScan();
    showToast("Scanning for devices");
  }

  void requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
    ].request();
  }
}
