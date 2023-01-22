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
    [0xAA, 0x55, 0x04, 0xB1, 0x00, 0x00, 0xB5],
    [0xB5, 0x00, 0x00, 0xB1, 0x04, 0x55, 0xAA],
    [0xAA, 0x55, 0x04, 0xB1, 0xB5],
    [0xB5, 0xB1, 0x04, 0x55, 0xAA],

  ];

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
        title: const Text("iF-H-D3 Protocol"),
      ),
      body: buildView(),
    );
  }

  ListView buildConnectDeviceView() {
    List<Container> containers = [];

    for (BluetoothService service in services) {
      List<Widget> characteristicsWidget = [];
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.value.listen((value) {
          print("value: ${value}");
        });
        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(characteristic.uuid.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ...buildReadWriteNotifyButton(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('Read value: ${readValues[characteristic.uuid]}'),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
        );
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

  List<ButtonTheme> buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = [];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MaterialButton(
              height: 50.0,
              minWidth: 150.0,
              color: Colors.white,
              textColor: Colors.green,
              splashColor: Theme.of(context).primaryColor,
              child: const Text(
                "Read",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MaterialButton(
              height: 50.0,
              minWidth: 150.0,
              color: Colors.white,
              textColor: Colors.green,
              splashColor: Theme.of(context).primaryColor,
              child: const Text(
                "Write",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          MaterialButton(
                            height: 50.0,
                            minWidth: 150.0,
                            color: Colors.white,
                            textColor: Colors.green,
                            splashColor: Theme.of(context).primaryColor,
                            child: const Text("Send"),
                            onPressed: () {
                              for(int i = 0; i < cmds.length; i++) {
                                Future.delayed(const Duration(seconds: 2), () async {
                                  var result = characteristic.write(cmds[i]);
                                });
                              }
                              characteristic.write(
                                  utf8.encode(writeController.value.text), withoutResponse: true);
                              writeController.text = '';
                              Navigator.pop(context);
                            },
                          ),
                          MaterialButton(
                            height: 50.0,
                            minWidth: 150.0,
                            color: Colors.white,
                            textColor: Colors.green,
                            splashColor: Theme.of(context).primaryColor,
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MaterialButton(
              height: 50.0,
              minWidth: 150.0,
              color: Colors.white,
              textColor: Colors.green,
              splashColor: Theme.of(context).primaryColor,
              child: const Text(
                "Notify",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                characteristic.value.listen((value) {
                  readValues[characteristic.uuid] = value;
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView buildListViewOfDevices() {
    List<SizedBox> containers = [];
    for (BluetoothDevice device in devicesList) {
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
                },
              ),
            ],
          ),
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

  ListView buildView() {
    if (connectedDevice != null) {
      return buildConnectDeviceView();
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
