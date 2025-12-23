import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/business_card.dart';
import '../utils/card_styles.dart';
import 'fabric_texture.dart';

class BusinessCardWidget extends StatelessWidget {
  final BusinessCard card;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onQrTap;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isCompact;

  const BusinessCardWidget({
    super.key,
    required this.card,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onQrTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildStandardCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    final textColor = CardStyles.getContrastColorForCategory(card.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: CardStyles.getGradientForCategory(card.category),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 3)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              const Positioned.fill(child: FabricTexture()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.name.isNotEmpty ? card.name : 'Unknown',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${card.title} • ${card.company}',
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) => onTap(),
                        fillColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.blue;
                          }
                          return Colors.white.withOpacity(0.5);
                        }),
                        checkColor: Colors.white,
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              card.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: textColor,
                              size: 20,
                            ),
                            onPressed: onFavoriteToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: onQrTap,
                            child: Icon(
                              Icons.qr_code,
                              color: textColor,
                              size: 20,
                            ),
                          ),
                        ],
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

  Widget _buildStandardCard(BuildContext context) {
    final textColor = CardStyles.getContrastColorForCategory(card.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: CardStyles.getGradientForCategory(card.category),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              const Positioned.fill(child: FabricTexture()),
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

              // Category Watermark
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(
                      CardStyles.getCategoryIcon(card.category),
                      size: 120,
                      color: Colors.white,
                    ),
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
                              card.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
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
                            fillColor: MaterialStateProperty.resolveWith((
                              states,
                            ) {
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
                                data:
                                    'BEGIN:VCARD\nVERSION:3.0\nN:${card.name}\nORG:${card.company}\nTEL:${card.phone}\nEMAIL:${card.email}\nEND:VCARD',
                                size: 32,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
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
}
