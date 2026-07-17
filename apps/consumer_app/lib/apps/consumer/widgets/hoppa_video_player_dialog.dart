import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

class HoppaVideoPlayerDialog extends StatefulWidget {
  final String videoPath;

  const HoppaVideoPlayerDialog({
    super.key,
    this.videoPath = 'assets/videos/hoppa_reklam.mp4',
  });

  @override
  State<HoppaVideoPlayerDialog> createState() => _HoppaVideoPlayerDialogState();
}

class _HoppaVideoPlayerDialogState extends State<HoppaVideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      }).catchError((error) {
        debugPrint("Video initialization failed: $error");
      });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE95D22); // Hoppa Orange

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header / Close button above the video player container
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            // Video Player Card Container
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The actual video
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showControls = !_showControls;
                                });
                              },
                              child: VideoPlayer(_controller),
                            ),

                            // Large center play/pause indicator on tap/pause
                            if (!_controller.value.isPlaying || _showControls)
                              IgnorePointer(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  child: Center(
                                    child: AnimatedOpacity(
                                      opacity: !_controller.value.isPlaying ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Bottom Controls Overlay
                            if (_showControls || !_controller.value.isPlaying)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.8),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Progress Bar / Timeline slider
                                      Row(
                                        children: [
                                          Text(
                                            _formatDuration(_controller.value.position),
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                activeTrackColor: primaryColor,
                                                inactiveTrackColor: Colors.white24,
                                                trackShape: const RoundedRectSliderTrackShape(),
                                                trackHeight: 4.0,
                                                thumbColor: Colors.white,
                                                thumbShape: const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6.0,
                                                ),
                                                overlayColor: primaryColor.withValues(alpha: 0.2),
                                                overlayShape: const RoundSliderOverlayShape(
                                                  overlayRadius: 14.0,
                                                ),
                                              ),
                                              child: Slider(
                                                value: _controller.value.position.inMilliseconds.toDouble().clamp(
                                                      0.0,
                                                      _controller.value.duration.inMilliseconds.toDouble(),
                                                    ),
                                                min: 0.0,
                                                max: _controller.value.duration.inMilliseconds.toDouble(),
                                                onChanged: (value) {
                                                  _controller.seekTo(
                                                    Duration(milliseconds: value.toInt()),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(_controller.value.duration),
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Action bar: Play/Pause and Mute
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Play / Pause button
                                          IconButton(
                                            icon: Icon(
                                              _controller.value.isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                            ),
                                            color: Colors.white,
                                            iconSize: 28,
                                            onPressed: _togglePlay,
                                          ),

                                          // Center text (Optional label or video title)
                                          Text(
                                            "Hoppa ile Tanışın!",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          // Mute / Unmute button
                                          IconButton(
                                            icon: Icon(
                                              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                            ),
                                            color: Colors.white,
                                            iconSize: 24,
                                            onPressed: _toggleMute,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.black87,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Video yükleniyor...",
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
