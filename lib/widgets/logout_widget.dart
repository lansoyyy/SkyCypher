import 'package:flutter/material.dart';
import 'package:skycypher/services/auth_service.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

Future<void> showLogoutDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: app_colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      title: const Text(
        'Logout Confirmation',
        style: TextStyle(
          fontFamily: 'Bold',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(
          fontFamily: 'Regular',
          color: Colors.white,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Regular',
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            try {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
                // The AuthWrapper will automatically redirect to login
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to logout: ${e.toString()}'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
          },
          child: Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'Regular',
              fontWeight: FontWeight.bold,
              color: app_colors.secondary,
            ),
          ),
        ),
      ],
    ),
  );
}
