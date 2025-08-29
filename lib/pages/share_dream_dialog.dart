import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import '../l10n/app_localizations.dart';

class ShareDreamDialog extends StatefulWidget {
  final SavedDream dream;

  const ShareDreamDialog({super.key, required this.dream});

  @override
  State<ShareDreamDialog> createState() => _ShareDreamDialogState();
}

class _ShareDreamDialogState extends State<ShareDreamDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.share, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.share),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            )!.confirmShareMessage.replaceAll('{title}', widget.dream.title),
            style: const TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.sharedDreamsVisibleInfo,
                    style: TextStyle(color: Colors.blue[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (widget.dream.isSharedWithCommunity) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.alreadySharedMessage,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelAction),
        ),
        if (!widget.dream.isSharedWithCommunity)
          ElevatedButton(
            onPressed: _isLoading ? null : _shareDream,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(AppLocalizations.of(context)!.share),
          )
        else
          ElevatedButton(
            onPressed: _isLoading ? null : _unshareDream,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(AppLocalizations.of(context)!.unshare),
          ),
      ],
    );
  }

  Future<void> _shareDream() async {
    setState(() => _isLoading = true);

    try {
      final dreamStorage = context.read<DreamStorageService>();
      await dreamStorage.updateDreamSharingStatus(widget.dream.id, true);

      Navigator.pop(context, true); // Ritorna true per indicare successo
      // Success feedback suppressed per UX request (no snackbar on success)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Errore nella condivisione: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unshareDream() async {
    setState(() => _isLoading = true);

    try {
      final dreamStorage = context.read<DreamStorageService>();
      await dreamStorage.updateDreamSharingStatus(widget.dream.id, false);

      Navigator.pop(context, true); // Ritorna true per indicare successo
      // Success feedback suppressed per UX request (no snackbar on success)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Errore: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
