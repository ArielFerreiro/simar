// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:cmbsdk_flutter/cmbsdk_flutter.dart';
import 'package:cmbsdk_flutter/cmbsdk_flutter_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simar/business_logic/bloc/wordline/wordline_bloc.dart';
import 'package:simar/data/repository/wordline_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  WordlineRepository repository = WordlineRepository();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<WordlineBloc>(
          create: (_) => WordlineBloc(repository: repository)),
    ],
    child: const MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  //----------------------------------------------------------------------------
  // The cmbSDK supports multi-code scanning (scanning multiple barcodes at
  // one time); thus scan results are returned as an array. Note that
  // this sample app does not demonstrate the use of these multi-code features.
  //----------------------------------------------------------------------------
  List<dynamic> _resultsArray = [];

  bool _isScanning = false;
  String _cmbSDKVersion = 'N/A';
  String _connectionStatusText = 'Desconectado';
  Color _connectionStatusBackground = Colors.redAccent;
  String _scanButtonText = '(NO CONNECTADO)';
  bool _scanButtonEnabled = false;

  final TextEditingController _umController = TextEditingController();
  final FocusNode _umFocusNode = FocusNode();

  //----------------------------------------------------------------------------
  // If USE_PRECONFIGURED_DEVICE is YES, then the app will create a reader
  // using the values of device/cameraMode. Otherwise, the app presents
  // a pick list for the user to select either MX-1xxx or the built-in camera.
  //----------------------------------------------------------------------------
  final bool _usePreconfiguredDevice = false;
  int _deviceType = cmbDeviceType.MXReader;
  int _cameraMode = cmbCameraMode.NoAimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    initCmbSDK();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
    switch (appLifecycleState) {
      case AppLifecycleState.resumed:
        cmb
            .connect()
            .catchError((error, stackTrace) => print('${error.message}'));
        break;
      case AppLifecycleState.inactive:
        if (_isScanning) {
          cmb
              .stopScanning()
              .catchError((error, stackTrace) => print('${error.message}'));
        }
        break;
      case AppLifecycleState.paused:
        cmb
            .disconnect()
            .catchError((error, stackTrace) => print('${error.message}'));
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> initCmbSDK() async {
    String cmbSDKVersion = 'N/A';

    // This is called when a MX-1xxx device has became available (USB cable was plugged, or MX device was turned on),
    // or when a MX-1xxx that was previously available has become unavailable (USB cable was unplugged, turned off due to inactivity or battery drained)
    cmb.setAvailabilityChangedListener((availability) {
      if (availability == cmbAvailability.Available.index) {
        cmb
            .connect()
            .catchError((error, stackTrace) => print('${error.message}'));
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text('Dispositivo desconectado'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });

    // This is called when a connection with the reader has been changed.
    // The reader is usable only in the "Connected" state
    cmb.setConnectionStateChangedListener((state) {
      if (state == cmbConnectionState.Connected.index) {
        _configureReaderDevice();

        _updateUIByConnectionState(cmbConnectionState.Connected);
      } else {
        _updateUIByConnectionState(cmbConnectionState.Disconnected);
      }

      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _resultsArray = [];
      });
    });

    // This is called after scanning has completed, either by detecting a barcode,
    // canceling the scan by using the on-screen button or a hardware trigger button, or if the scanning timed-out
    cmb.setReadResultReceivedListener((resultJSON) {
      final Map<String, dynamic> resultMap = jsonDecode(resultJSON);
      final List<dynamic> resultsArray = resultMap['results'];

      if (!mounted) return;

      setState(() {
        _resultsArray = resultsArray;
        if (_resultsArray.isNotEmpty) {
          if (_resultsArray.length == 1) {
            String result = _resultsArray[0]['readString'];
            if (result.startsWith('LEWL')) {
              BlocProvider.of<WordlineBloc>(context)
                  .add(RetrieveWordlineData(um: result));
            } else {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Codigo erroneo"),
                      content: const Text("Leyo un codigo y no es de SIMAR"),
                      actions: <Widget>[
                        TextButton(
                          child: const Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  });
            }
          } else {
            bool found = false;
            for (int i = 0; i < _resultsArray.length; i++) {
              String result = _resultsArray[i]['readString'];
              if (result.startsWith('LEWL')) {
                found = true;
                BlocProvider.of<WordlineBloc>(context)
                    .add(RetrieveWordlineData(um: result));
              } else {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Codigos erroneo"),
                        content: const Text(
                            "Leyo mas de un codigo y ninguno es de SIMAR"),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    });
              }
            }
            if (!found) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Codigos erroneos"),
                    content: const Text(
                        "Leyo multiples codigos y ninguno es de SIMAR"),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
        }
      });
    });

    // It will return TRUE in the result if the scanning process is STARTED and false if it's STOPPED
    cmb.setScanningStateChangedListener((scanningState) {
      if (!mounted) return;

      setState(() {
        _isScanning = scanningState;
        _scanButtonText = _isScanning ? 'DETENGA SCANNER' : 'COMIENCE SCANNER';
      });
    });

    // Get cmbSDK version number
    cmbSDKVersion = await cmb.sdkVersion;

    //initialize and connect to MX/Phone Camera here
    if (_usePreconfiguredDevice) {
      _createReaderDevice();
    } else {
      _selectDeviceFromPicker();
    }

    if (!mounted) return;

    setState(() {
      _cmbSDKVersion = cmbSDKVersion;
    });
  }

  // Update the UI of the app (scan button, connection state label) depending on the current connection state
  void _updateUIByConnectionState(cmbConnectionState state) {
    String connectionStatusText = _connectionStatusText;
    Color connectionStatusBackground = _connectionStatusBackground;
    String scanButtonText = _scanButtonText;
    bool scanButtonEnabled = _scanButtonEnabled;

    if (state == cmbConnectionState.Connected) {
      connectionStatusText = 'Conectado';
      connectionStatusBackground = Colors.lightGreen;

      scanButtonText = 'COMIENCE SCANNER';
      scanButtonEnabled = true;
    } else {
      connectionStatusText = 'Desconectado';
      connectionStatusBackground = Colors.redAccent;

      scanButtonText = '(NO CONECTADO)';
      scanButtonEnabled = false;
    }

    if (!mounted) return;

    setState(() {
      _connectionStatusText = connectionStatusText;
      _connectionStatusBackground = connectionStatusBackground;

      _scanButtonText = scanButtonText;
      _scanButtonEnabled = scanButtonEnabled;
    });
  }

  //----------------------------------------------------------------------------
  // This is the pick list for choosing the type of reader connection
  //----------------------------------------------------------------------------
  Future<void> _selectDeviceFromPicker() async {
    int deviceType = _deviceType;
    int cameraMode = _cameraMode;

    switch (await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Seleccione dispositivo'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, cmbDeviceType.MXReader);
                },
                child: const Text('MX Scanner (MX-1xxx)'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, cmbDeviceType.Camera);
                },
                child: const Text('Camara'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, null);
                },
                child: const Text('Cancelar'),
              ),
            ],
          );
        })) {
      case cmbDeviceType.MXReader:
        deviceType = cmbDeviceType.MXReader;
        break;
      case cmbDeviceType.Camera:
        deviceType = cmbDeviceType.Camera;
        cameraMode = cmbCameraMode.NoAimer;
        // ...
        break;
      default:
        // dialog dismissed
        break;
    }

    if (!mounted) return;

    setState(() {
      _deviceType = deviceType;
      _cameraMode = cameraMode;
    });

    _createReaderDevice();
  }

  // Create a reader using the selected option from "selectDeviceFromPicker"
  void _createReaderDevice() {
    cmb.setCameraMode(_cameraMode);
    cmb.setPreviewOptions(cmbPrevewiOption.Defaults);

    cmb.registerSDK("Vf0i3jUSWyrX99hlxTUV8a3goBh0yzzbhTpcsGvgSB8=");
    cmb.loadScanner(_deviceType).then((value) {
      cmb.connect().then((value) {
        _updateUIByConnectionState(cmbConnectionState.Connected);
      }).catchError((error, stackTrace) {
        _updateUIByConnectionState(cmbConnectionState.Disconnected);
      });
    });
  }

  //----------------------------------------------------------------------------
  // This is an example of configuring the device. In this sample application, we
  // configure the device every time the connection state changes to connected (see
  // the ConnectionStateChanged event), as this is the best
  // way to garentee it is setup the way we want it. Not only does this garentee
  // that the device is configured when we initially connect, but also covers the
  // case where an MX scanner has hibernated (and we're reconnecting)--unless
  // setting changes are explicitly saved to non-volatile memory, they can be lost
  // when the MX hibernates or reboots.
  //
  // These are just example settings; in your own application you will want to
  // consider which setting changes are optimal for your application. It is
  // important to note that the different supported devices have different, out
  // of the box defaults:
  //
  //    * MX-1xxx Mobile Terminals have the following symbologies enabled by default:
  //        - Data Matrix
  //        - UPC/EAN
  //        - Code 39
  //        - Code 93
  //        - Code 128
  //        - Interleaved 2 of 5
  //        - Codabar
  //    * camera scanner has NO symbologies enabled by default
  //
  // For the best scanning performance, it is recommended to only have the barcode
  // symbologies enabled that your application actually needs to scan. If scanning
  // with an MX-1xxx, that may mean disabling some of the defaults (or enabling
  // symbologies that are off by default).
  //
  // Keep in mind that this sample application works with all three types of devices,
  // so in our example below we show explicitly enabling symbologies as well as
  // explicitly disabling symbologies (even if those symbologies may already be on/off
  // for the device being used).
  //
  // We also show how to send configuration commands that may be device type
  // specific--again, primarily for demonstration purposes.
  //----------------------------------------------------------------------------
  void _configureReaderDevice() {
    //----------------------------------------------
    // Explicitly enable the symbologies we need
    //----------------------------------------------
    cmb
        .setSymbologyEnabled(cmbSymbology.DataMatrix, true)
        .then((value) => print('DataMatrix enabled'))
        .catchError((error, stackTrace) =>
            print('DataMatrix NOT enabled. ${error.message}'));

    cmb
        .setSymbologyEnabled(cmbSymbology.C128, true)
        .catchError((error, stackTrace) => print('${error.message}'));
    cmb
        .setSymbologyEnabled(cmbSymbology.UpcEan, true)
        .catchError((error, stackTrace) => print('${error.message}'));

    //-------------------------------------------------------
    // Explicitly disable symbologies we know we don't need
    //-------------------------------------------------------
    cmb
        .setSymbologyEnabled(cmbSymbology.CodaBar, false)
        .then((value) => print('CodaBar disabled'))
        .catchError((error, stackTrace) =>
            print('CodaBar NOT disabled. ${error.message}'));

    cmb
        .setSymbologyEnabled(cmbSymbology.C93, false)
        .catchError((error, stackTrace) => print('${error.message}'));

    //---------------------------------------------------------------------------
    // Below are examples of sending DMCC commands and getting the response
    //---------------------------------------------------------------------------
    cmb
        .sendCommand('GET DEVICE.TYPE')
        .then((value) => print('$value'))
        .catchError((error, stackTrace) => print('${error.message}'));

    cmb
        .sendCommand('GET DEVICE.FIRMWARE-VER')
        .then((value) => print('$value'))
        .catchError((error, stackTrace) => print('${error.message}'));

    //---------------------------------------------------------------------------
    // We are going to explicitly turn off image results (although this is the
    // default). The reason is that enabling image results with an MX-1xxx
    // scanner is not recommended unless your application needs the scanned
    // image--otherwise scanning performance can be impacted.
    //---------------------------------------------------------------------------
    cmb
        .enableImage(false)
        .catchError((error, stackTrace) => print('${error.message}'));
    cmb
        .enableImageGraphics(false)
        .catchError((error, stackTrace) => print('${error.message}'));

    //---------------------------------------------------------------------------
    // Device specific configuration examples
    //---------------------------------------------------------------------------
    if (_deviceType == cmbDeviceType.Camera) {
      //---------------------------------------------------------------------------
      // Phone/tablet
      //---------------------------------------------------------------------------

      // Set the SDK's decoding effort to level 3
      cmb
          .sendCommand("SET DECODER.EFFORT 3")
          .catchError((error, stackTrace) => print('${error.message}'));
    } else if (_deviceType == cmbDeviceType.MXReader) {
      //---------------------------------------------------------------------------
      // MX-1xxx
      //---------------------------------------------------------------------------

      //---------------------------------------------------------------------------
      // Save our configuration to non-volatile memory
      // If the MX hibernates or is rebooted, our settings will be retained.
      //---------------------------------------------------------------------------
      cmb
          .sendCommand("CONFIG.SAVE")
          .catchError((error, stackTrace) => print('${error.message}'));
    }
  }

  void _toggleScanner() {
    //Inicializo el estado
    BlocProvider.of<WordlineBloc>(context).add(ResetState());
    if (_isScanning) {
      cmb
          .stopScanning()
          .catchError((error, stackTrace) => print('${error.message}'));
    } else {
      cmb
          .startScanning()
          .catchError((error, stackTrace) => print('${error.message}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff333333),
      appBar: AppBar(
        title: const Text('SRI DEMO'),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: () {
                  _selectDeviceFromPicker();
                },
                child: const Text('DISPOSITIVO'),
              )),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            /*
            Expanded(
                child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _resultsArray.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${_resultsArray[index]['readString']}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                            Text('${_resultsArray[index]['symbologyString']}',
                                style: const TextStyle(color: Colors.grey)),
                          ]);
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(thickness: 1))),
                  */
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _umController,
                      focusNode: _umFocusNode,
                      cursorColor: Colors.white,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                          focusColor: Colors.yellow,
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow)),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 2),
                          ),
                          labelText: 'Busqueda manual',
                          labelStyle: TextStyle(color: Colors.white)),
                      keyboardType: TextInputType.text,
                      autovalidateMode: AutovalidateMode.always,
                      autocorrect: false,
                      style: const TextStyle(color: Colors.white),
                      onTap: () {
                        BlocProvider.of<WordlineBloc>(context)
                            .add(ResetState());
                        _umController.text = 'LEWL3';
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  IconButton(
                      color: Colors.white,
                      onPressed: () {
                        if (_umController.text.length != 13 ||
                            !_umController.text.startsWith('LEWL3')) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Texto erroneo"),
                                  content: const Text(
                                      "El codigo debe contener 13 caracteres y empezar con LEWL3"),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text("OK"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              });
                        } else {
                          FocusManager.instance.primaryFocus?.unfocus();
                          BlocProvider.of<WordlineBloc>(context).add(
                              RetrieveWordlineData(um: _umController.text));
                        }
                      },
                      icon: const Icon(
                        Icons.find_in_page,
                        color: Colors.yellow,
                      )),
                ],
              ),
            ),
            _buildResults(context),
            //TODO AGREGAR CAMPO MANUAL
            Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _scanButtonEnabled
                          ? () {
                              _toggleScanner();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                          primary: const Color(0xfffadb04),
                          onPrimary: Colors.black,
                          onSurface: const Color(0xfffadb04)),
                      child: Text(_scanButtonText),
                    ))),
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(_cmbSDKVersion,
                        style: const TextStyle(
                          color: Colors.white,
                        )),
                    Container(
                      color: _connectionStatusBackground,
                      child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(_connectionStatusText,
                              style: const TextStyle(
                                color: Colors.white,
                              ))),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<WordlineBloc, WordlineState>(builder: (_, state) {
      if (state is WordlineLoading) {
        return const Expanded(
            child: Center(
          child: CircularProgressIndicator.adaptive(),
        ));
      } else if (state is WordlineNoData) {
        return Expanded(
          child: Column(children: [
            Text('${_resultsArray[0]['readString']}',
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text('${_resultsArray[0]['symbologyString']}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(
              height: 16,
            ),
            const Text('No se encontro ningun dato para el codigo',
                style: TextStyle(color: Colors.white)),
          ]),
        );
      } else if (state is WordlineDataLoaded) {
        return Expanded(
          child: Column(
            children: [
              Text('${_resultsArray[0]['readString']}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('${_resultsArray[0]['symbologyString']}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(
                height: 16,
              ),
              const Text('RUC Productor', style: TextStyle(color: Colors.grey)),
              Text('${state.data.rucProducer}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 8,
              ),
              const Text('Nombre Productor',
                  style: TextStyle(color: Colors.grey)),
              Text(
                '${state.data.registeredNameProducer}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 8,
              ),
              const Text('Origen', style: TextStyle(color: Colors.grey)),
              Text('${state.data.productOrigine}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 8,
              ),
              const Text('ICE Producto', style: TextStyle(color: Colors.grey)),
              Text('${state.data.iceProduct}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 8,
              ),
              const Text('Fecha Activación',
                  style: TextStyle(color: Colors.grey)),
              Text('${state.data.activationDate}',
                  style: const TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
        );
      } else {
        return const Expanded(
          child: Center(
            child: Text(
              'Comience leyendo un codigo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    });
  }
}
