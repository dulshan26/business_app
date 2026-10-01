import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────
//  COLOR TOKENS  (matches Fairwall dark theme)
// ─────────────────────────────────────────────
const _kBg = Color(0xFF0D0D1A);
const _kSurface = Color(0xFF16162A);
const _kCard = Color(0xFF1E1E35);
const _kBorder = Color(0xFF2E2E50);
const _kAccent = Color(0xFF7C3AED);
const _kAccentLight = Color(0xFF9F67FF);
const _kSuccess = Color(0xFF22C55E);
const _kError = Color(0xFFEF4444);
const _kTextPrimary = Color(0xFFEAEAFF);
const _kTextSecondary = Color(0xFF8888AA);

class _PickedImage {
  final Uint8List bytes;
  final String name;
  _PickedImage({required this.bytes, required this.name});
}

class ImageUploadWidget extends StatefulWidget {
  final void Function(String downloadUrl)? onUploaded;
  final String storagePath;

  const ImageUploadWidget({
    super.key,
    this.onUploaded,
    this.storagePath = 'uploads/',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

enum _UploadStatus { idle, uploading, success, error }

class _ImageUploadWidgetState extends State<ImageUploadWidget>
    with SingleTickerProviderStateMixin {
  _PickedImage? _picked;
  _UploadStatus _status = _UploadStatus.idle;
  double _progress = 0;
  String? _downloadUrl;
  String? _errorMsg;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  StreamSubscription<TaskSnapshot>? _uploadSubscription; // Fixes memory leak

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _cancelUploadSubscription();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _cancelUploadSubscription() {
    _uploadSubscription?.cancel();
    _uploadSubscription = null;
  }

  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _picked = _PickedImage(bytes: bytes, name: file.name);
      _status = _UploadStatus.idle;
      _downloadUrl = null;
      _errorMsg = null;
    });

    _showPreviewModal();
  }

  Future<void> _startUpload() async {
    if (_picked == null) return;

    setState(() {
      _status = _UploadStatus.uploading;
      _progress = 0;
    });

    try {
      final ext = _picked!.name.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path =
          '${widget.storagePath}${DateTime.now().millisecondsSinceEpoch}.$ext';

      final ref = FirebaseStorage.instance.ref().child(path);
      final task = ref.putData(
        _picked!.bytes,
        SettableMetadata(contentType: contentType),
      );

      // Secure stream tracking
      _cancelUploadSubscription();
      _uploadSubscription = task.snapshotEvents.listen(
        (snap) {
          if (!mounted) return;
          setState(() {
            // Defend against division by zero if totalBytes is 0
            _progress = snap.totalBytes > 0
                ? (snap.bytesTransferred / snap.totalBytes).clamp(0.0, 1.0)
                : 0.0;
          });
        },
        onError: (err) {
          _handleError(err.toString());
        },
      );

      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();

      _cancelUploadSubscription();

      if (!mounted) return;
      setState(() {
        _status = _UploadStatus.success;
        _downloadUrl = url;
      });
      widget.onUploaded?.call(url);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String message) {
    _cancelUploadSubscription();
    if (!mounted) return;
    setState(() {
      _status = _UploadStatus.error;
      _errorMsg = message;
    });
  }

  void _discard() {
    setState(() {
      _picked = null;
      _status = _UploadStatus.idle;
    });
  }

  void _reset() => setState(() {
    _picked = null;
    _status = _UploadStatus.idle;
    _downloadUrl = null;
    _errorMsg = null;
    _progress = 0;
  });

  void _showPreviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _PreviewModal(
        image: _picked!,
        onSave: () {
          Navigator.of(modalContext).pop(); // Clean execution context close
          _startUpload();
        },
        onDiscard: () {
          Navigator.of(modalContext).pop();
          _discard();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          'Upload Image',
          style: _ts(16, FontWeight.w600, _kTextPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _UploadStatus.uploading:
        return _UploadingView(progress: _progress, pulse: _pulse);
      case _UploadStatus.success:
        return _SuccessView(
          url: _downloadUrl ?? '',
          imageBytes: _picked?.bytes,
          onReset: _reset,
        );
      case _UploadStatus.error:
        return _ErrorView(
          message: _errorMsg ?? 'Unknown error',
          onRetry: _reset,
        );
      case _UploadStatus.idle:
        return _IdleView(onPick: _pickImage);
    }
  }
}

// ─────────────────────────────────────────────
//  IDLE VIEW  — With Custom Dash Painter Added
// ─────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final VoidCallback onPick;
  const _IdleView({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onPick,
              child: CustomPaint(
                painter: _DashBorderPainter(),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.symmetric(
                    vertical: 56,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Color(0x557C3AED), Colors.transparent],
                            radius: 0.9,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_rounded,
                          size: 48,
                          color: _kAccentLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tap to choose an image',
                        style: _ts(16, FontWeight.w600, _kTextPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JPG, PNG · up to 10 MB',
                        style: _ts(13, FontWeight.w400, _kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _GradientButton(
              label: 'Choose Image',
              icon: Icons.image_rounded,
              onTap: onPick,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHED BORDER PAINTER
// ─────────────────────────────────────────────
class _DashBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final path = Path()..addRRect(rrect);
    final dashWidth = 6.0;
    final dashSpace = 4.0;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = dashWidth;
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + len).clamp(0.0, metric.length),
          ),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  PREVIEW MODAL
// ─────────────────────────────────────────────
class _PreviewModal extends StatelessWidget {
  final _PickedImage image;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _PreviewModal({
    required this.image,
    required this.onSave,
    required this.onDiscard,
  });

  String get _readableSize {
    final kb = image.bytes.length / 1024;
    return kb > 1024
        ? '${(kb / 1024).toStringAsFixed(1)} MB'
        : '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_outlined,
                  color: _kAccentLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Preview', style: _ts(17, FontWeight.w700, _kTextPrimary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kTextSecondary),
                  onPressed: onDiscard,
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 16,
                    color: _kTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      image.name,
                      style: _ts(13, FontWeight.w500, _kTextPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _readableSize,
                    style: _ts(12, FontWeight.w400, _kTextSecondary),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _OutlineButton(label: 'Discard', onTap: onDiscard),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _GradientButton(
                    label: 'Upload',
                    icon: Icons.cloud_upload_rounded,
                    onTap: onSave,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  UPLOADING VIEW
// ─────────────────────────────────────────────
class _UploadingView extends StatelessWidget {
  final double progress;
  final Animation<double> pulse;
  const _UploadingView({required this.progress, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: pulse,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kAccent, Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.5),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Uploading…', style: _ts(18, FontWeight.w600, _kTextPrimary)),
            const SizedBox(height: 8),
            Text('$pct%', style: _ts(13, FontWeight.w500, _kTextSecondary)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: _kBorder,
                valueColor: const AlwaysStoppedAnimation(_kAccentLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUCCESS VIEW
// ─────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String url;
  final Uint8List? imageBytes;
  final VoidCallback onReset;

  const _SuccessView({
    required this.url,
    required this.imageBytes,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    imageBytes!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _kSuccess,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Upload complete!',
            style: _ts(20, FontWeight.w700, _kTextPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your image is now stored in Firebase Storage.',
            style: _ts(13, FontWeight.w400, _kTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kSuccess.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: _kSuccess, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    url,
                    style: _ts(11, FontWeight.w400, _kTextSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _GradientButton(
            label: 'Upload another',
            icon: Icons.add_photo_alternate_rounded,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ERROR VIEW
// ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kError.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: _kError,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload failed',
              style: _ts(18, FontWeight.w700, _kTextPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kError.withValues(alpha: 0.3)),
              ),
              child: Text(
                message,
                style: _ts(12, FontWeight.w400, _kTextSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            _GradientButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED BUTTONS
// ─────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kAccent, Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: _pressed ? 0.2 : 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(widget.label, style: _ts(14, FontWeight.w600, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: _ts(14, FontWeight.w600, _kTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _ts(double size, FontWeight weight, Color color) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.2,
);
