import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAboutTab extends StatelessWidget {
  const HelpAboutTab({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Help & Support Section
        _buildSectionHeader('Help & Support'),
        const SizedBox(height: 12),
        _buildListTile(
          context,
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Browse FAQs and guides',
          onTap: () {
            // Navigate to help screen (to be implemented)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help Center - Coming soon')),
            );
          },
        ),
        _buildListTile(
          context,
          icon: Icons.email_outlined,
          title: 'Contact Support',
          subtitle: 'support@knowvas.com',
          onTap: () => _launchEmail('support@knowvas.com'),
        ),
        _buildListTile(
          context,
          icon: Icons.chat_bubble_outline,
          title: 'WhatsApp Support',
          subtitle: 'Chat with us',
          onTap: () => _launchUrl('https://wa.me/2348134764684'),
        ),

        const SizedBox(height: 24),

        // About Section
        _buildSectionHeader('About Knowvas'),
        const SizedBox(height: 12),
        _buildListTile(
          context,
          icon: Icons.info_outline,
          title: 'About Us',
          subtitle: 'Learn about our mission',
          onTap: () {
            // Navigate to about screen (to be implemented)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('About Us - Coming soon')),
            );
          },
        ),
        _buildListTile(
          context,
          icon: Icons.star_outline,
          title: 'Rate Us',
          subtitle: 'Share your feedback',
          onTap: () {
            // Open app store rating
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rate Us - Coming soon')),
            );
          },
        ),
        _buildListTile(
          context,
          icon: Icons.share_outlined,
          title: 'Share App',
          subtitle: 'Tell your friends',
          onTap: () {
            // Share app functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share App - Coming soon')),
            );
          },
        ),

        const SizedBox(height: 24),

        // Legal Section
        _buildSectionHeader('Legal'),
        const SizedBox(height: 12),
        _buildListTile(
          context,
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          subtitle: 'Read our terms',
          onTap: () => _launchUrl('https://knowvas.com/terms'),
        ),
        _buildListTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'How we protect your data',
          onTap: () => _launchUrl('https://knowvas.com/privacy'),
        ),
        _buildListTile(
          context,
          icon: Icons.cookie_outlined,
          title: 'Cookie Policy',
          subtitle: 'How we use cookies',
          onTap: () => _launchUrl('https://knowvas.com/cookies'),
        ),
        _buildListTile(
          context,
          icon: Icons.shield_outlined,
          title: 'Content Protection',
          subtitle: 'Our content security',
          onTap: () => _launchUrl('https://knowvas.com/content-protection'),
        ),
        _buildListTile(
          context,
          icon: Icons.people_outline,
          title: 'Community Standards',
          subtitle: 'Our community guidelines',
          onTap: () => _launchUrl('https://knowvas.com/community-standards'),
        ),

        const SizedBox(height: 24),

        // Social Media Section
        _buildSectionHeader('Connect With Us'),
        const SizedBox(height: 12),
        _buildListTile(
          context,
          icon: Icons.language,
          title: 'Website',
          subtitle: 'knowvas.com',
          onTap: () => _launchUrl('https://knowvas.com'),
        ),
        _buildListTile(
          context,
          icon: Icons.video_library_outlined,
          title: 'YouTube',
          subtitle: 'Watch tutorials',
          onTap: () => _launchUrl('https://www.youtube.com/@Knowvasng'),
        ),
        _buildListTile(
          context,
          icon: Icons.alternate_email,
          title: 'Twitter',
          subtitle: '@Knowvasng',
          onTap: () => _launchUrl('https://twitter.com/Knowvasng'),
        ),
        _buildListTile(
          context,
          icon: Icons.facebook_outlined,
          title: 'Facebook',
          subtitle: 'Follow us',
          onTap: () => _launchUrl('https://facebook.com/knowvas'),
        ),
        _buildListTile(
          context,
          icon: Icons.camera_alt_outlined,
          title: 'Instagram',
          subtitle: '@knowvas',
          onTap: () => _launchUrl('https://instagram.com/knowvas'),
        ),

        const SizedBox(height: 24),

        // App Info Section
        _buildSectionHeader('App Information'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Version',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Build',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Text(
                    '100',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Copyright
        Center(
          child: Column(
            children: [
              Text(
                '© 2025 Knowvas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Made with ❤️ in Nigeria',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8B5CF6),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
