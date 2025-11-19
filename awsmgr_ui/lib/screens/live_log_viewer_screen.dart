import 'package:flutter/material.dart';
import 'dart:async';
import '../services/cloudwatch_service.dart';
import '../theme/app_theme.dart';

class LiveLogViewerScreen extends StatefulWidget {
  final String functionName;

  const LiveLogViewerScreen({
    super.key,
    required this.functionName,
  });

  @override
  State<LiveLogViewerScreen> createState() => _LiveLogViewerScreenState();
}

class _LiveLogViewerScreenState extends State<LiveLogViewerScreen> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<LogEntry>? _logSubscription;
  bool _isPaused = false;
  bool _autoScroll = true;
  bool _isSearchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _startStreaming();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // Enable auto-scroll if user scrolls to bottom
      if (currentScroll >= maxScroll - 50) {
        if (!_autoScroll) {
          setState(() {
            _autoScroll = true;
          });
        }
      } else {
        // Disable auto-scroll if user scrolls up
        if (_autoScroll) {
          setState(() {
            _autoScroll = false;
          });
        }
      }
    }
  }

  void _startStreaming() {
    _logSubscription = CloudWatchService.streamLambdaLogs(widget.functionName).listen(
      (logEntry) {
        if (!_isPaused) {
          setState(() {
            _logs.add(logEntry);
            _updateSearchMatches();
          });
          
          if (_autoScroll && _scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stream error: $error'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      },
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _resetLogs() {
    setState(() {
      _logs.clear();
      _searchMatches.clear();
      _currentMatchIndex = -1;
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        _searchFocusNode.requestFocus();
      } else {
        _searchQuery = '';
        _searchController.clear();
        _searchMatches.clear();
        _currentMatchIndex = -1;
      }
    });
  }

  void _updateSearchMatches() {
    if (_searchQuery.isEmpty) {
      _searchMatches.clear();
      _currentMatchIndex = -1;
      return;
    }

    _searchMatches.clear();
    final query = _searchQuery.toLowerCase();
    
    for (int i = 0; i < _logs.length; i++) {
      if (_logs[i].message.toLowerCase().contains(query)) {
        _searchMatches.add(i);
      }
    }

    if (_searchMatches.isNotEmpty) {
      if (_currentMatchIndex == -1 || _currentMatchIndex >= _searchMatches.length) {
        _currentMatchIndex = 0;
        _scrollToMatch();
      }
    } else {
      _currentMatchIndex = -1;
    }
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      _scrollToMatch();
    });
  }

  void _prevMatch() {
    if (_searchMatches.isEmpty) return;
    
    setState(() {
      _currentMatchIndex--;
      if (_currentMatchIndex < 0) {
        _currentMatchIndex = _searchMatches.length - 1;
      }
      _scrollToMatch();
    });
  }

  void _scrollToMatch() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _searchMatches.length) {
      return;
    }
    
    if (!_scrollController.hasClients) return;
    
    final matchLine = _searchMatches[_currentMatchIndex];
    
    // Calculate the position to scroll to
    // We want to center the match in the viewport
    final viewportHeight = _scrollController.position.viewportDimension;
    final itemHeight = 24.0; // Approximate height per log line
    final targetScroll = (matchLine * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    
    // Clamp to valid scroll range
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedScroll = targetScroll.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      clampedScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'green':
        return Colors.green;
      case 'cyan':
        return Colors.cyan;
      case 'blue':
        return Colors.blue;
      case 'magenta':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Live Tail: ${widget.functionName}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearchMode,
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetLogs,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchMode) _buildSearchBar(),
          _buildStatusBar(),
          Expanded(
            child: _logs.isEmpty
                ? _buildEmptyState()
                : _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.teal.shade900,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
                suffixText: _searchMatches.isNotEmpty
                    ? '${_currentMatchIndex + 1}/${_searchMatches.length}'
                    : null,
                suffixStyle: const TextStyle(color: Colors.white),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _updateSearchMatches();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            onPressed: _prevMatch,
            tooltip: 'Previous match',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
            onPressed: _nextMatch,
            tooltip: 'Next match',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSearchMode,
            tooltip: 'Close search',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isPaused ? Colors.red.shade900 : Colors.green.shade900,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isPaused ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isPaused ? 'PAUSED' : 'LIVE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '|',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 16),
          Text(
            _autoScroll ? 'AUTO' : 'MANUAL',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            'Logs: ${_logs.length}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for logs...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invoke the Lambda function to see logs',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final isMatch = _searchQuery.isNotEmpty &&
            log.message.toLowerCase().contains(_searchQuery.toLowerCase());
        final isCurrentMatch = isMatch &&
            _searchMatches.isNotEmpty &&
            _currentMatchIndex >= 0 &&
            _currentMatchIndex < _searchMatches.length &&
            _searchMatches[_currentMatchIndex] == index;

        return Container(
          key: ValueKey('log_$index'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: isCurrentMatch
              ? Colors.yellow.shade700
              : isMatch
                  ? Colors.yellow.shade900.withValues(alpha: 0.3)
                  : Colors.transparent,
          child: _searchQuery.isNotEmpty && isMatch
              ? _buildHighlightedText(log.message, log.color, isCurrentMatch)
              : SelectableText(
                  log.message,
                  style: TextStyle(
                    color: _getColorFromString(log.color),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, String color, bool isCurrentMatch) {
    final textColor = isCurrentMatch ? Colors.black : _getColorFromString(color);
    final query = _searchQuery.toLowerCase();
    final textLower = text.toLowerCase();
    
    final spans = <TextSpan>[];
    int start = 0;
    
    while (start < text.length) {
      final index = textLower.indexOf(query, start);
      if (index == -1) {
        // No more matches, add remaining text
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(
            color: textColor,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ));
        break;
      }
      
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            color: textColor,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: isCurrentMatch ? Colors.black : Colors.black,
          backgroundColor: isCurrentMatch 
              ? Colors.orange.shade400 
              : Colors.yellow.shade600,
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
    }
    
    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}
