import 'package:flutter/material.dart';
import 'package:iot_app/presentation/Crud/getDelete.dart';
import 'package:iot_app/presentation/bluetooth_messaging/bluetoothConnection.dart';
import 'package:iot_app/presentation/network_messaging/protocol_selection_screen.dart';

class FooterNav extends StatefulWidget {
  const FooterNav({super.key});

  @override
  State<FooterNav> createState() => _FooterNavState();
}

class _FooterNavState extends State<FooterNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    UsersDetails(),
    ProtocolSelectionScreen(),
    Bluetoothconnection()
  ];

  final List<IconData> _icons = [
    Icons.person,
    Icons.network_cell,
    Icons.bluetooth
  ];

  final List<String> _labels = [
    "CRUD",
    "Network",
    "Bluetooth",
  ];

  @override
  Widget build(BuildContext context) {
    final blockWidth = MediaQuery.of(context).size.width /100;
    final blockHeight = MediaQuery.of(context).size.height /100;
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex], 
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: blockWidth * 4,
          vertical: blockHeight * 4
        ),
        child: Container(
          height: blockHeight * 9.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.pink,
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withAlpha(35),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              final isSelected = _currentIndex == index;
              return InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: blockWidth * 2.5,
                    vertical: blockHeight * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withAlpha(15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icons[index],
                        color: isSelected ? Colors.white : Colors.white70,
                        size: isSelected
                            ? blockWidth * 7
                            : blockWidth * 6,
                      ),
                      if (isSelected)
                        Padding(
                          padding: EdgeInsets.only(
                              top: blockHeight * 0.6),
                          child: Text(
                            _labels[index],
                            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                           
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
