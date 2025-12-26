import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';

class SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String?  confirmationTitle;
  final String? confirmationMessage;
  final bool requireConfirmation;

  const SwipeToDelete({
    super.key,
    required this. child,
    required this.onDelete,
    this.confirmationTitle,
    this.confirmationMessage,
    this.requireConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (! requireConfirmation) {
          return true;
        }

        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(confirmationTitle ?? 'Delete'),
            content: Text(
              confirmationMessage ?? 'Are you sure you want to delete this item?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed:  (direction) {
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets. only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius. circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: child,
    );
  }
}