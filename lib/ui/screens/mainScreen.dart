/*
 * Copyright (c) 2022 DivVPN
 * Distributed under the GNU GPL v2 with additional terms. For full terms see the file doc/LICENSE.txt
 */

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:open_divvpn/core/models/dnsConfig.dart';
import 'package:open_divvpn/core/models/vpnConfig.dart';
import 'package:open_divvpn/core/models/vpnStatus.dart';
import 'package:open_divvpn/core/utils/divvpn_engine.dart';
import 'package:flutter/services.dart' show rootBundle;

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _vpnState = DivVPN.vpnDisconnected;
  List<VpnConfig> _listVpn = [];
  VpnConfig? _selectedVpn;

  @override
  void initState() {
    super.initState();

    ///Add listener to update vpnstate
    DivVPN.vpnStageSnapshot().listen((event) {
      setState(() {
        _vpnState = event;
      });
    });

    ///Call initVpn
    initVpn();
  }

  ///Here you can start fill the listVpn, for this simple app, i'm using free vpn from https://www.vpngate.net/
  void initVpn() async {
    _listVpn.add(VpnConfig(config: await rootBundle.loadString("assets/vpn/us.ovpn"), name: "United State"));
    if (mounted)
      setState(() {
        _selectedVpn = _listVpn.first;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OpenVPN by Nizwar"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: StadiumBorder(),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    _vpnState == DivVPN.vpnDisconnected ? "Connect VPN!" : _vpnState.replaceAll("_", " ").toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _connectClick,
                ),
              ),
              StreamBuilder<VpnStatus?>(
                initialData: VpnStatus(),
                stream: DivVPN.vpnStatusSnapshot(),
                builder: (context, snapshot) => Text("${snapshot.data?.byteIn ?? ""}, ${snapshot.data?.byteOut ?? ""}", textAlign: TextAlign.center),
              )
            ]
              //i just make it simple, hope i'm not making you to much confuse
              ..addAll(
                _listVpn.isNotEmpty
                    ? _listVpn.map(
                        (e) => ListTile(
                          title: Text(e.name),
                          leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Center(child: _selectedVpn == e ? CircleAvatar(backgroundColor: Colors.green) : CircleAvatar(backgroundColor: Colors.grey)),
                          ),
                          onTap: () {
                            if (_selectedVpn == e) return;
                            log("${e.name} is selected");
                            DivVPN.stopVpn();
                            setState(() {
                              _selectedVpn = e;
                            });
                          },
                        ),
                      )
                    : [],
              ),
          ),
        ),
      ),
    );
  }

  void _connectClick() {
    ///Stop right here if user not select a vpn
    if (_selectedVpn == null) return;

    if (_vpnState == DivVPN.vpnDisconnected) {
      ///Start if stage is disconnected
      DivVPN.startVpn(
        _selectedVpn!,
        dns: DnsConfig("23.253.163.53", "198.101.242.72"),
      );
    } else {
      ///Stop if stage is "not" disconnected
      NizVpn.stopVpn();
    }
  }
}
