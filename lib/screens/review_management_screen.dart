// lib/screens/review_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/reviews_service.dart';
import 'package:nearnest/models/review.dart';
import 'package:intl/intl.dart';

class ReviewManagementScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const ReviewManagementScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen>
    with TickerProviderStateMixin {
  final ReviewsService _reviewsService = ReviewsService();
  Map<String, dynamic>? _reviewStats;
  bool _isLoadingStats = true;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadReviewStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewStats() async {
    try {
      final stats = await _reviewsService.getBusinessReviewStats(widget.businessId);
      setState(() {
        _reviewStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    _buildTabSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'Review Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.reviews_rounded,
                color: Colors.white24,
                size: 80,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return _buildLoadingStats();
    }

    if (_reviewStats == null) {
      return _buildErrorStats();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Review Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Reviews',
                  _reviewStats!['totalReviews'].toString(),
                  Icons.reviews_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Average Rating',
                  _reviewStats!['averageRating'].toStringAsFixed(1),
                  Icons.star_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Response Rate',
                  '${_reviewStats!['responseRate'].toStringAsFixed(0)}%',
                  Icons.reply_rounded,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Recent Reviews',
                  _reviewStats!['recentReviews'].toString(),
                  Icons.schedule_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF1E293B),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'All Reviews'),
                Tab(text: 'Needs Response'),
                Tab(text: 'Responded'),
              ],
            ),
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsList(filter: 'all'),
                _buildReviewsList(filter: 'needs_response'),
                _buildReviewsList(filter: 'responded'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList({required String filter}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reviewsService.getBusinessReviews(widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingList();
        }

        if (snapshot.hasError) {
          return _buildErrorList();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyList();
        }

        List<QueryDocumentSnapshot> reviews = snapshot.data!.docs;

        // Filter reviews based on tab
        if (filter == 'needs_response') {
          reviews = reviews.where((doc) {
            final review = Review.fromMap(doc.data() as Map<String, dynamic>);
            return !review.hasResponse;
          }).toList();
        } else if (filter == 'responded') {
          reviews = reviews.where((doc) {
            final review = Review.fromMap(doc.data() as Map<String, dynamic>);
            return review.hasResponse;
          }).toList();
        }

        if (reviews.isEmpty) {
          return _buildEmptyFilteredList(filter);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildReviewCard(reviews[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewCard(QueryDocumentSnapshot doc) {
    final review = Review.fromMap(doc.data() as Map<String, dynamic>);
    final hasResponse = review.hasResponse;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasResponse 
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFF59E0B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRatingColor(review.rating),
                      _getRatingColor(review.rating).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.userName ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasResponse 
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasResponse ? 'Responded' : 'Needs Response',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasResponse 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(review.createdAt.toDate()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Customer Review Content
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),
          ],

          // Business Response Section
          if (hasResponse) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.business_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Response from ${review.respondedBy ?? widget.businessName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const Spacer(),
                      if (review.responseDate != null)
                        Text(
                          DateFormat('MMM d, yyyy').format(review.responseDate!.toDate()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.businessResponse!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          const SizedBox(height: 16),
          Row(
            children: [
              if (!hasResponse) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showResponseDialog(review),
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    label: const Text('Respond'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResponseDialog(review, isEdit: true),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Response'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteResponseDialog(review),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF10B981);
    if (rating >= 3.0) return const Color(0xFFF59E0B);
    if (rating >= 2.0) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  void _showResponseDialog(Review review, {bool isEdit = false}) {
    final TextEditingController responseController = TextEditingController();
    if (isEdit && review.businessResponse != null) {
      responseController.text = review.businessResponse!;
    }
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.reply_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Response' : 'Respond to Review',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Show customer review context
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < review.rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          review.comment!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'Your Response',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: responseController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Thank you for your feedback...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (responseController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a response'),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isSubmitting = true);
                                
                                try {
                                  if (isEdit) {
                                    await _reviewsService.updateBusinessResponse(
                                      itemId: widget.businessId,
                                      customerId: review.userId,
                                      response: responseController.text.trim(),
                                    );
                                  } else {
                                    await _reviewsService.addBusinessResponse(
                                      itemId: widget.businessId,
                                      customerId: review.userId,
                                      response: responseController.text.trim(),
                                    );
                                  }
                                  
                                  Navigator.pop(context);
                                  _showSuccessMessage(isEdit ? 'Response updated successfully!' : 'Response added successfully!');
                                  HapticFeedback.lightImpact();
                                } catch (e) {
                                  _showErrorMessage('Failed to ${isEdit ? 'update' : 'add'} response: $e');
                                } finally {
                                  setState(() => isSubmitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? 'Update' : 'Respond'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteResponseDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Response'),
        content: const Text('Are you sure you want to delete this response? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _reviewsService.deleteBusinessResponse(
                  itemId: widget.businessId,
                  customerId: review.userId,
                );
                Navigator.pop(context);
                _showSuccessMessage('Response deleted successfully!');
                HapticFeedback.lightImpact();
              } catch (e) {
                _showErrorMessage('Failed to delete response: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildErrorStats() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Failed to load statistics',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildErrorList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Failed to load reviews',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.reviews_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Reviews will appear here once customers start rating your business',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredList(String filter) {
    String title = '';
    String subtitle = '';
    
    switch (filter) {
      case 'needs_response':
        title = 'All caught up!';
        subtitle = 'You\'ve responded to all reviews that need attention';
        break;
      case 'responded':
        title = 'No responses yet';
        subtitle = 'Start responding to reviews to build customer relationships';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'needs_response' ? Icons.check_circle_outline : Icons.reply_outlined,
              size: 48,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}