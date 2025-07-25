import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';

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
          SizedBox(width: 8),
          Text('Condividi con la Community'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vuoi condividere "${widget.dream.title}" con la community?',
            style: TextStyle(fontSize: 16),
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
                    'Il tuo sogno sarà visibile a tutti gli utenti della community in modo anonimo.',
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
                      'Questo sogno è già condiviso con la community.',
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
          child: Text('Annulla'),
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
                : Text('Condividi'),
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
                : Text('Rimuovi condivisione'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Sogno condiviso con la community!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Condivisione rimossa!'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
