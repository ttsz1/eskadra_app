import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../domain/models/chat_attachment.dart';
import '../../domain/models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.isMine,
    required this.formatTime,
    required this.buildSignedUrl,
    this.onDelete,
    super.key,
  });

  final ChatMessage message;
  final bool isMine;
  final String Function(DateTime value) formatTime;
  final Future<String> Function(String storagePath) buildSignedUrl;
  final VoidCallback? onDelete;

  bool _isImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        message.senderName,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (message.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(message.content),
                ],
                if (message.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Column(
                    children: message.attachments
                        .map(
                          (attachment) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AttachmentTile(
                              attachment: attachment,
                              isImage: _isImage(attachment.fileName),
                              buildSignedUrl: buildSignedUrl,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.isImage,
    required this.buildSignedUrl,
  });

  final ChatAttachment attachment;
  final bool isImage;
  final Future<String> Function(String storagePath) buildSignedUrl;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: buildSignedUrl(attachment.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isImage
                  ? Icons.image_outlined
                  : Icons.insert_drive_file_outlined,
            ),
            title: Text(attachment.fileName),
            subtitle: const Text('Ładowanie...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isImage
                  ? Icons.broken_image_outlined
                  : Icons.insert_drive_file_outlined,
            ),
            title: Text(attachment.fileName),
            subtitle: const Text('Nie udało się pobrać linku'),
          );
        }

        final signedUrl = snapshot.data!;

        if (isImage) {
          return InkWell(
            onTap: () => launchUrlString(
              signedUrl,
              mode: LaunchMode.externalApplication,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    signedUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.image_not_supported_outlined),
                      title: Text(attachment.fileName),
                      onTap: () => launchUrlString(
                        signedUrl,
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  attachment.fileName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(attachment.fileName),
          subtitle: attachment.fileSizeBytes != null
              ? Text('${attachment.fileSizeBytes} B')
              : null,
          onTap: () => launchUrlString(
            signedUrl,
            mode: LaunchMode.externalApplication,
          ),
        );
      },
    );
  }
}
