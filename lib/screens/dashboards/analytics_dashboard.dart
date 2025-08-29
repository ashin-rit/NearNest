// lib/screens/dashboards/analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: const Color(0xFFB91C1C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Distribution',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }
                final users = userSnapshot.data!.docs;
                final totalCustomers = users.where((user) => user['role'] == 'Customer').length;
                final totalShops = users.where((user) => user['role'] == 'Shop').length;
                final totalServices = users.where((user) => user['role'] == 'Services').length;

                return _buildUserRoleChart(totalCustomers, totalShops, totalServices);
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Booking Status Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (context, bookingSnapshot) {
                if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (bookingSnapshot.hasError) {
                  return Center(child: Text('Error: ${bookingSnapshot.error}'));
                }
                final bookings = bookingSnapshot.data!.docs;
                final pendingBookings = bookings.where((b) => b['status'] == 'Pending').length;
                final confirmedBookings = bookings.where((b) => b['status'] == 'Confirmed').length;
                final canceledBookings = bookings.where((b) => b['status'] == 'Canceled').length;

                return _buildBookingStatusChart(pendingBookings, confirmedBookings, canceledBookings);
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'User Growth Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _fetchUserGrowthData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No user data to display.'));
                }

                return _buildLineChart(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _fetchUserGrowthData() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('created_at')
        .get();

    final Map<String, int> dailyUserGrowth = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final timestamp = data['created_at'] as Timestamp;
      final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());

      dailyUserGrowth.update(date, (value) => value + 1, ifAbsent: () => 1);
    }
    return dailyUserGrowth;
  }

  Widget _buildUserRoleChart(int totalCustomers, int totalShops, int totalServices) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: const Color(0xFF34D399),
              value: totalCustomers.toDouble(),
              title: 'Customers\n(${totalCustomers})',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: const Color(0xFFFACC15),
              value: totalShops.toDouble(),
              title: 'Shops\n(${totalShops})',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: const Color(0xFF38BDF8),
              value: totalServices.toDouble(),
              title: 'Services\n(${totalServices})',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBookingStatusChart(int pendingBookings, int confirmedBookings, int canceledBookings) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(toY: pendingBookings.toDouble(), color: Colors.orange, width: 20),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(toY: confirmedBookings.toDouble(), color: Colors.green, width: 20),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(toY: canceledBookings.toDouble(), color: Colors.red, width: 20),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Pending';
                      break;
                    case 1:
                      text = 'Confirmed';
                      break;
                    case 2:
                      text = 'Canceled';
                      break;
                    default:
                      text = '';
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 40),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
  
  Widget _buildLineChart(Map<String, int> data) {
    final List<FlSpot> spots = [];
    final dates = data.keys.toList()..sort();
    for (int i = 0; i < dates.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[dates[i]]!.toDouble()));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < dates.length) {
                    final date = dates[value.toInt()];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(DateFormat('MMM dd').format(DateTime.parse(date)),
                          style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
                interval: 1,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFB91C1C),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}