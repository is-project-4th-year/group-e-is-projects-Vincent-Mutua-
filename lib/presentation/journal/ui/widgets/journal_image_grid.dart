// Force rebuild comment
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';

class JournalImageGrid extends ConsumerWidget {
  const JournalImageGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(journalEditorProvider);
    
    if (editorState.imageUrls.isEmpty && editorState.localImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: editorState.imageUrls.length + editorState.localImages.length,
        itemBuilder: (context, index) {
          if (index < editorState.imageUrls.length) {
            return _buildImageThumbnail(ref, url: editorState.imageUrls[index], isLocal: false);
          } else {
            final localIndex = index - editorState.imageUrls.length;
            return _buildImageThumbnail(ref, file: editorState.localImages[localIndex], isLocal: true);
          }
        },
      ),
    );
  }

  Widget _buildImageThumbnail(WidgetRef ref, {String? url, XFile? file, required bool isLocal}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.black12,
            child: isLocal
                ? Image.file(
                    File(file!.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading local image: $error");
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  )
                : Image.network(
                    url!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading network image: $error");
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              if (isLocal) {
                ref.read(journalEditorProvider.notifier).removeLocalImage(file!);
              } else {
                ref.read(journalEditorProvider.notifier).removeImageUrl(url!);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
