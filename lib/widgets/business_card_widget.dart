import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/business_card.dart';
import '../utils/card_styles.dart';

class BusinessCardWidget extends StatelessWidget {
  final BusinessCard card;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onQrTap;
  final bool isSelectionMode;
  final bool isSelected;

  const BusinessCardWidget({
    super.key,
    required this.card,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onQrTap,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CardStyles.getContrastColor(card.colorIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: CardStyles.getGradient(card.colorIndex),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 3)
              : null,
        ),
        child: Stack(
          children: [
            // Decorative Circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo / Image Placeholder
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          image: card.imagePath.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(card.imagePath)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: card.imagePath.isEmpty
                            ? Icon(Icons.business, color: textColor, size: 20)
                            : null,
                      ),
                      if (!isSelectionMode)
                        IconButton(
                          icon: Icon(
                            card.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: textColor,
                          ),
                          onPressed: onFavoriteToggle,
                        )
                      else
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            onTap();
                          },
                          fillColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue;
                            }
                            return Colors.white.withOpacity(0.5);
                          }),
                          checkColor: Colors.white,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.name.isNotEmpty ? card.name : 'Unknown',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    card.title,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.company,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  if (!isSelectionMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                         GestureDetector(
                           onTap: onQrTap,
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: QrImageView(
                               data: 'BEGIN:VCARD\nVERSION:3.0\nN:${card.name}\nORG:${card.company}\nTEL:${card.phone}\nEMAIL:${card.email}\nEND:VCARD',
                               size: 32,
                               padding: EdgeInsets.zero,
                             ),
                           ),
                         ),
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
