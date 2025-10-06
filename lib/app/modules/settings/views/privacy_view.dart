import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:flutter/material.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5568), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Privacy & Policy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFBFC),
              Color(0xFFF7FAFC),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Privacy & Data Protection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your privacy and data security are our top priorities',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF1E40AF).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // License Agreement Section
              _buildPolicySection(
                'License Agreement & Data Processing',
                Icons.description,
                const Color(0xFF10B981),
                'Effective Date: 05/25/2025',
                [
                  'Limited, non-exclusive license for personal use',
                  'User data collection and processing consent',
                  'Data security and protection measures',
                  'User rights and data access',
                  'Termination and agreement changes',
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Data Collection Section
              _buildPolicySection(
                'Data Collection & Usage',
                Icons.data_usage,
                const Color(0xFF8B5CF6),
                'What we collect and how we use it',
                [
                  'Account information (email, username, password)',
                  'User-generated content and posts',
                  'Device and usage analytics',
                  'Location data for map features',
                  'Communication preferences',
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Security Section
              _buildPolicySection(
                'Data Security',
                Icons.shield,
                const Color(0xFFF59E0B),
                'How we protect your information',
                [
                  'Encryption for data transmission',
                  'Secure server infrastructure',
                  'Regular security audits',
                  'Access controls and authentication',
                  'Incident response procedures',
                ],
              ),
              
              const SizedBox(height: 24),
              
              // User Rights Section
              _buildPolicySection(
                'Your Rights',
                Icons.person_outline,
                const Color(0xFFEF4444),
                'What you can control',
                [
                  'Access and download your data',
                  'Request data correction or deletion',
                  'Withdraw consent for processing',
                  'Opt-out of communications',
                  'File complaints or concerns',
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Child Safety Section
              _buildPolicySection(
                'Child Safety Standards',
                Icons.child_care,
                const Color(0xFF06B6D4),
                'Protecting young users',
                [
                  'Minimum age requirement (13+)',
                  'Parental supervision guidelines',
                  'Content moderation protocols',
                  'Reporting abuse mechanisms',
                  'COPPA compliance measures',
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Contact Section
              _buildContactSection(),
              
              const SizedBox(height: 32),
              
              // Footer Message
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Privacy Matters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We\'re committed to protecting your data and privacy',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF92400E).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, IconData icon, Color color, String subtitle, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A202C).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF718096),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Questions about our privacy policy? We\'re here to help!',
            style: TextStyle(
              fontSize: 15,
              color: const Color(0xFF1E40AF).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email, 'Email', 'support@chys.app'),
          const SizedBox(height: 8),
          _buildContactItem(Icons.location_on, 'Address', '235 W 48TH Street, 10036 New York, NY, USA'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For child safety concerns, contact: contact@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
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

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        Expanded( // ✅ Make texts responsive
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E40AF),
                ),
                maxLines: 1, // ✅ Prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1E40AF).withOpacity(0.8),
                ),
                maxLines: 1, // ✅ Prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    ;
  }
}
