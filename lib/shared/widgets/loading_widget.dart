import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taftaf/core/constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.overlay,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

class PropertyCardShimmer extends StatelessWidget {
  const PropertyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.surfaceColor,
      highlightColor: context.cardColor,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class TaftafLogo extends StatelessWidget {
  final double size;
  final bool showDot;

  const TaftafLogo({super.key, this.size = 48, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Smart image widget — uses FileImage for local paths, CachedNetworkImage for URLs.
class PropertyImageWidget extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const PropertyImageWidget({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: Colors.grey.shade800,
        child: const Icon(Icons.home_rounded, color: Colors.grey, size: 36),
      );

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return _fallback();
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => placeholder ?? Container(width: width, height: height, color: Colors.grey.shade800),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }
}

/// Avatar image — supports local path, network URL, or initials fallback.
class UserAvatarWidget extends StatelessWidget {
  final String? profilePic;
  final String displayName;
  final double radius;

  const UserAvatarWidget({
    super.key,
    required this.profilePic,
    required this.displayName,
    this.radius = 20,
  });

  Widget _initials() => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
          style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pic = profilePic;
    if (pic == null || pic.isEmpty) return _initials();

    // Network URL — CachedNetworkImage handles decode & error
    if (pic.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: pic,
        imageBuilder: (_, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          backgroundImage: imageProvider,
        ),
        placeholder: (_, _) => _initials(),
        errorWidget: (_, _, _) => _initials(),
        width: radius * 2,
        height: radius * 2,
      );
    }

    // Local file — Image.file with errorBuilder gives a reliable fallback
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: Image.file(
          File(pic),
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (_, _, _) => _initials(),
        ),
      ),
    );
  }
}
