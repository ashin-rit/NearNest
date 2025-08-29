// lib/screens/dashboards/analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Analytics & Reports',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFB91C1C),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildWelcomeSection(),
                const SizedBox(height: 32),
                _buildMetricsRow(),
                const SizedBox(height: 40),
                _buildSectionHeader('Distribution Analytics', Icons.pie_chart),
                const SizedBox(height: 20),
                _buildChartsRow([
                  _buildChartContainer('User Distribution', _buildUserRoleChart()),
                  _buildChartContainer('Top Services', _buildTopServicesChart()),
                ]),
                const SizedBox(height: 40),
                _buildSectionHeader('Performance Metrics', Icons.bar_chart),
                const SizedBox(height: 20),
                _buildChartsRow([
                  _buildChartContainer('Booking Status', _buildBookingStatusChart()),
                  _buildChartContainer('Order Status', _buildOrderStatusChart()),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time insights into your business performance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB91C1C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFB91C1C),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow(List<Widget> charts) {
    if (MediaQuery.of(context).size.width < 768) {
      return Column(
        children: charts
            .map((chart) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: chart,
                ))
            .toList(),
      );
    }
    
    return Row(
      children: charts
          .map((chart) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: chart,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchKeyMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMetricsLoadingState();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildMetricsErrorState();
        }

        final metrics = snapshot.data!;
        final metricItems = [
          MetricItem('Total Users', metrics['totalUsers'].toString(), 
                    Icons.group, const Color(0xFF3B82F6)),
          MetricItem('Total Bookings', metrics['totalBookings'].toString(), 
                    Icons.calendar_today, const Color(0xFF8B5CF6)),
          MetricItem('Total Orders', metrics['totalOrders'].toString(), 
                    Icons.shopping_cart, const Color(0xFF10B981)),
          MetricItem('Total Shops', metrics['totalShops'].toString(), 
                    Icons.store, const Color(0xFFF59E0B)),
          MetricItem('Total Providers', metrics['totalServiceProviders'].toString(), 
                    Icons.business_center, const Color(0xFF06B6D4)),
        ];

        if (MediaQuery.of(context).size.width < 768) {
          return Column(
            children: metricItems
                .asMap()
                .entries
                .map((entry) => TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (entry.key * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildEnhancedMetricCard(entry.value),
                            ),
                          ),
                        );
                      },
                    ))
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: metricItems
                .asMap()
                .entries
                .map((entry) => TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (entry.key * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _buildEnhancedMetricCard(entry.value),
                            ),
                          ),
                        );
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildMetricsLoadingState() {
    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            height: 120,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsErrorState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: const Center(
        child: Text(
          'Error fetching metrics',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEnhancedMetricCard(MetricItem item) {
    return Container(
      width: MediaQuery.of(context).size.width < 768 ? double.infinity : 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: item.color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '↗ Live',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 1500),
            tween: IntTween(begin: 0, end: int.parse(item.value)),
            builder: (context, value, child) {
              return Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoleChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
          ));
        }
        if (userSnapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${userSnapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }
        
        final users = userSnapshot.data!.docs;
        final totalCustomers = users.where((user) => user['role'] == 'Customer').length;
        final totalShops = users.where((user) => user['role'] == 'Shop').length;
        final totalServices = users.where((user) => user['role'] == 'Services').length;

        if (totalCustomers == 0 && totalShops == 0 && totalServices == 0) {
          return const Center(child: Text('No user data available'));
        }

        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                color: const Color(0xFF10B981),
                value: totalCustomers.toDouble(),
                title: 'Customers\n($totalCustomers)',
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: const Color(0xFFF59E0B),
                value: totalShops.toDouble(),
                title: 'Shops\n($totalShops)',
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: const Color(0xFF3B82F6),
                value: totalServices.toDouble(),
                title: 'Services\n($totalServices)',
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
            centerSpaceRadius: 50,
            sectionsSpace: 2,
          ),
        );
      },
    );
  }

  Widget _buildBookingStatusChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, bookingSnapshot) {
        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
          ));
        }
        if (bookingSnapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${bookingSnapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }
        
        final bookings = bookingSnapshot.data!.docs;
        final pendingBookings = bookings.where((b) => b['status'] == 'Pending').length;
        final confirmedBookings = bookings.where((b) => b['status'] == 'Confirmed').length;
        final canceledBookings = bookings.where((b) => b['status'] == 'Canceled').length;

        return BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: pendingBookings.toDouble(),
                    color: const Color(0xFFF59E0B),
                    width: 25,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: confirmedBookings.toDouble(),
                    color: const Color(0xFF10B981),
                    width: 25,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: canceledBookings.toDouble(),
                    color: const Color(0xFFEF4444),
                    width: 25,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
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
                      case 0: text = 'Pending'; break;
                      case 1: text = 'Confirmed'; break;
                      case 2: text = 'Canceled'; break;
                      default: text = ''; break;
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            backgroundColor: Colors.transparent,
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
          ));
        }
        if (orderSnapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${orderSnapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }
        
        final orders = orderSnapshot.data!.docs;
        final pendingOrders = orders.where((b) => b['status'] == 'Pending').length;
        final confirmedOrders = orders.where((b) => b['status'] == 'Confirmed').length;
        final deliveredOrders = orders.where((b) => b['status'] == 'Delivered').length;
        final pickedUpOrders = orders.where((b) => b['status'] == 'Picked Up').length;
        final canceledOrders = orders.where((b) => b['status'] == 'Canceled').length;

        return BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: pendingOrders.toDouble(),
                    color: const Color(0xFF3B82F6),
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: confirmedOrders.toDouble(),
                    color: const Color(0xFF10B981),
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: deliveredOrders.toDouble(),
                    color: const Color(0xFFF59E0B),
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 3,
                barRods: [
                  BarChartRodData(
                    toY: pickedUpOrders.toDouble(),
                    color: const Color(0xFF84CC16),
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 4,
                barRods: [
                  BarChartRodData(
                    toY: canceledOrders.toDouble(),
                    color: const Color(0xFFEF4444),
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
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
                      case 0: text = 'Pending'; break;
                      case 1: text = 'Confirmed'; break;
                      case 2: text = 'Delivered'; break;
                      case 3: text = 'Picked Up'; break;
                      case 4: text = 'Canceled'; break;
                      default: text = ''; break;
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopServicesChart() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchTopServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
          ));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No service data to display.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }
        
        final List<BarChartGroupData> barGroups = [];
        final titles = snapshot.data!.keys.toList();
        final colors = [
          const Color(0xFFEF4444),
          const Color(0xFFF59E0B),
          const Color(0xFF10B981),
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
        ];

        for (int i = 0; i < titles.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: snapshot.data![titles[i]]!.toDouble(),
                  color: colors[i % colors.length],
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }

        return BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < titles.length) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          titles[index].length > 8 
                              ? '${titles[index].substring(0, 8)}...'
                              : titles[index],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
          ),
        );
      },
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

  Future<Map<String, int>> _fetchTopServices() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    final Map<String, int> serviceBookings = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final serviceName = data['serviceName'] as String?;
      if (serviceName != null && serviceName.isNotEmpty) {
        serviceBookings.update(serviceName, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final sortedEntries = serviceBookings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, int> top5Services = {};
    for (int i = 0; i < sortedEntries.length && i < 5; i++) {
      top5Services[sortedEntries[i].key] = sortedEntries[i].value;
    }

    return top5Services;
  }

  Future<Map<String, dynamic>> _fetchKeyMetrics() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    final ordersSnapshot = await FirebaseFirestore.instance.collection('orders').get();

    final totalUsers = usersSnapshot.docs.length;
    final totalBookings = bookingsSnapshot.docs.length;
    final totalOrders = ordersSnapshot.docs.length;
    final totalShops = usersSnapshot.docs.where((user) => user['role'] == 'Shop').length;
    final totalServiceProviders = usersSnapshot.docs.where((user) => user['role'] == 'Services').length;

    return {
      'totalUsers': totalUsers,
      'totalBookings': totalBookings,
      'totalOrders': totalOrders,
      'totalShops': totalShops,
      'totalServiceProviders': totalServiceProviders,
    };
  }
}

class MetricItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  MetricItem(this.title, this.value, this.icon, this.color);
}