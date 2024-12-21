import 'package:cass/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node-RED Dashboard'),
        backgroundColor: const Color.fromARGB(186, 243, 18, 2),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().signout(context: context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool tempAlert = false;
  bool humidityAlert = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlobalDataSection(),
                const SizedBox(height: 16),
                _buildAlertsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalDataSection() {
    final cassCollection = FirebaseFirestore.instance.collection('cass');

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Global Data",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: cassCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No data available.",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final cassData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final temperature = cassData['Temperature'];
                final humidite = cassData['Humidity'];
                final intensite = cassData['intensite'];
                final tension = cassData['tension'];
                final ledstatus = cassData['LEDStatus'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow("Temperature", "$temperature °C"),
                    _buildDataRow("Humidity", "$humidite %"),
                    _buildDataRow("Intensity", "$intensite Lux"),
                    _buildDataRow("Voltage", "$tension V"),
                    _buildDataRow("LED Status", ledstatus ? "ON" : "OFF"),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    final cassCollection = FirebaseFirestore.instance.collection('cass');

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Controls",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: cassCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No data available.",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final doc = snapshot.data!.docs.first;
                final cassData = doc.data() as Map<String, dynamic>;
                final ledStatus = cassData['LEDStatus'] ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "LED",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    FlutterSwitch(
                      width: 70.0,
                      height: 35.0,
                      valueFontSize: 16.0,
                      toggleSize: 25.0,
                      value: ledStatus,
                      onToggle: (val) async {
                        try {
                          await cassCollection.doc(doc.id).update({
                            'LEDStatus': val,
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update LED status: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
