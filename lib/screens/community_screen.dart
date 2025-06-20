import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/post.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/comment.dart';
import '../services/post_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  int _page = 0;
  String? _currentUserId;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      setState(() {
        _currentUserId = authService.currentUser?.uid;
      });
    });
    _fetchPosts(initial: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts({bool initial = false}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      if (initial) {
        _posts = [];
        _lastDocument = null;
        _hasMore = true;
      }
      final query = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(10);
      QuerySnapshot snapshot;
      if (_lastDocument != null) {
        snapshot = await query.startAfterDocument(_lastDocument!).get();
      } else {
        snapshot = await query.get();
      }
      final newPosts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Post.fromJson(data);
      }).toList();
      setState(() {
        if (initial) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }
        _isLoading = false;
        _hasMore = newPosts.length == 10;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _toggleLike(Post post) async {
    if (_currentUserId == null) return;
    final liked = post.likedBy(_currentUserId!);
    await _postService.toggleLike(
      postId: post.id,
      userId: _currentUserId!,
      like: !liked,
    );
    setState(() {
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        final newLikes = Map<String, bool>.from(_posts[idx].likes);
        if (liked) {
          newLikes.remove(_currentUserId!);
        } else {
          newLikes[_currentUserId!] = true;
        }
        _posts[idx] = post.copyWith(likes: newLikes);
      }
    });
  }

  void _openCommentsModal(Post post) async {
    final postService = PostService();
    final userId = _currentUserId;
    if (userId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return _CommentsModal(
          post: post,
          currentUserId: userId,
          postService: postService,
        );
      },
    );
  }

  void _openCreatePostModal() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return _CreatePostModal(
          userId: user.uid ?? '',
          userName: user.displayName ?? 'Anonymous',
          userProfileImageUrl: user.photoURL,
          onPostCreated: () async {
            Navigator.of(modalContext).pop();
            await _fetchPosts(initial: true);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Community',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: context.onSurfaceVariantColor,
        ),
      ),
      body: _hasError
          ? Center(child: Text('An error occurred', style: context.bodyLarge))
          : _posts.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchPosts(initial: true);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _posts.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = _posts[index];
                      return _PostCard(
                        post: post,
                        isLiked: _currentUserId != null
                            ? post.likedBy(_currentUserId!)
                            : false,
                        likeCount: post.likeCount,
                        onLike: () => _toggleLike(post),
                        onComment: () {
                          _openCommentsModal(post);
                        },
                        currentUserId: _currentUserId,
                        postService: _postService,
                      );
                    },
                  ),
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 8),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: context.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: () {
                  _openCreatePostModal();
                },
                tooltip: 'Create post',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final String? currentUserId;
  final PostService? postService;

  const _PostCard({
    required this.post,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onComment,
    required this.currentUserId,
    this.postService,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;
  bool _reporting = false;

  void _toggleReport() async {
    if (widget.currentUserId == null || widget.postService == null) return;
    setState(() => _reporting = true);
    final alreadyReported = widget.post.reportedBy(widget.currentUserId!);
    await widget.postService!.reportPost(
      postId: widget.post.id,
      userId: widget.currentUserId!,
      report: !alreadyReported,
    );
    setState(() => _reporting = false);
    // Optionnel : tu peux aussi rafraîchir les posts ici si besoin
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final content = post.content;
    final isLong = content.length > 256;
    final displayContent =
        !_expanded && isLong ? content.substring(0, 256) + '...' : content;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: context.largeBorderRadius),
      elevation: 0,
      color: context.surfaceColor,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: context.largeBorderRadius,
          boxShadow: [context.cardShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserAvatar(imageUrl: post.userProfileImageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(post.userName,
                                style: context.titleMedium
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_formatDate(post.createdAt),
                            style: context.bodyMedium.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag, size: 22),
                    color: (widget.currentUserId != null &&
                            widget.post.reportedBy(widget.currentUserId!))
                        ? context.errorColor
                        : context.grey500,
                    onPressed: _reporting ? null : _toggleReport,
                    tooltip: 'Report',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(post.title,
                  style: context.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(displayContent, style: context.bodyMedium),
              if (isLong)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'See less' : 'See more',
                        style: context.bodyMedium
                            .copyWith(color: context.primaryColor)),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: widget.isLiked
                          ? context.primaryColor
                          : context.onSurfaceVariantColor,
                    ),
                    onPressed: widget.onLike,
                    tooltip: 'Like',
                  ),
                  Text('${widget.likeCount}', style: context.bodyMedium),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.comment,
                        color: context.onSurfaceVariantColor),
                    onPressed: widget.onComment,
                    tooltip: 'Comment',
                  ),
                  Text('${widget.post.commentCount}',
                      style: context.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? imageUrl;
  const _UserAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: context.grey200,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Icon(Icons.person, color: context.grey500, size: 28)
          : null,
    );
  }
}

String _formatDate(DateTime date) {
  // Format: Day Month Hour:Minute (ex: 12 Apr 14:30)
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[month - 1];
}

class _CommentsModal extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final PostService postService;
  const _CommentsModal(
      {required this.post,
      required this.currentUserId,
      required this.postService});

  @override
  State<_CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<_CommentsModal> {
  List<Comment> _comments = [];
  bool _loading = true;
  bool _error = false;
  final TextEditingController _controller = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final comments = await widget.postService.fetchComments(widget.post.id);
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _toggleLike(Comment comment) async {
    final isLiked = comment.likedBy(widget.currentUserId);
    await widget.postService.toggleCommentLike(
      postId: widget.post.id,
      commentId: comment.id,
      userId: widget.currentUserId,
      like: !isLiked,
    );
    final updated = comment.copyWith(
      likes: Map<String, bool>.from(comment.likes)
        ..[widget.currentUserId] = !isLiked,
    );
    setState(() {
      _comments =
          _comments.map((c) => c.id == comment.id ? updated : c).toList();
    });
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _adding = true;
    });
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final comment = Comment(
      id: '',
      postId: widget.post.id,
      userId: user?.uid ?? '',
      userName: user?.displayName ?? 'Anonymous',
      userProfileImageUrl: user?.photoURL,
      content: text,
      createdAt: DateTime.now(),
    );
    await widget.postService.addComment(comment);
    _controller.clear();
    await _fetchComments();
    setState(() {
      _adding = false;
    });
  }

  void _onReportComment(Comment comment) async {
    final userId = widget.currentUserId;
    if (userId == null) return;
    final alreadyReported = comment.reportedBy(userId);
    setState(() {
      _comments = _comments.map((c) {
        if (c.id == comment.id) {
          final newReports = Map<String, bool>.from(c.reports);
          newReports[userId] = !alreadyReported;
          return c.copyWith(reports: newReports);
        }
        return c;
      }).toList();
    });
    await widget.postService.reportComment(
      postId: widget.post.id,
      commentId: comment.id,
      userId: userId,
      report: !alreadyReported,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double popinHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: popinHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  height:
                      20), // Padding top pour éviter que le titre ne soit collé
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Comments',
                  style: context.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error
                        ? Center(
                            child: Text('Failed to load comments',
                                style: context.bodyLarge))
                        : _comments.isEmpty
                            ? Center(
                                child: Text('No comments yet',
                                    style: context.bodyLarge))
                            : ListView.builder(
                                itemCount: _comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  final isLiked =
                                      comment.likedBy(widget.currentUserId);
                                  return ListTile(
                                    leading: null,
                                    title: Text(comment.userName,
                                        style: context.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDate(comment.createdAt),
                                          style: context.bodyMedium.copyWith(
                                              fontSize: 12,
                                              color: context.grey500),
                                        ),
                                        Text(comment.content,
                                            style: context.bodyMedium),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isLiked
                                                    ? context.primaryColor
                                                    : context
                                                        .onSurfaceVariantColor,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _toggleLike(comment),
                                              tooltip: 'Like',
                                            ),
                                            Text('${comment.likeCount}',
                                                style: context.bodyMedium
                                                    .copyWith(fontSize: 13)),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              icon: const Icon(Icons.flag,
                                                  size: 20),
                                              color: (comment.reportedBy !=
                                                          null &&
                                                      widget.currentUserId !=
                                                          null &&
                                                      comment.reportedBy(
                                                          widget.currentUserId))
                                                  ? context.errorColor
                                                  : context.grey500,
                                              onPressed: () =>
                                                  _onReportComment(comment),
                                              tooltip: 'Report',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: context.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _adding
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: Icon(Icons.send, color: context.primaryColor),
                          onPressed: _addComment,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePostModal extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final VoidCallback onPostCreated;
  const _CreatePostModal(
      {required this.userId,
      required this.userName,
      this.userProfileImageUrl,
      required this.onPostCreated});

  @override
  State<_CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<_CreatePostModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _titleError = false;
  bool _contentError = false;
  String? _feedback;
  bool _success = false;

  Future<void> _submit() async {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty;
      _contentError = _contentController.text.trim().isEmpty;
      _feedback = null;
      _success = false;
    });
    if (_titleError || _contentError) return;
    try {
      final post = Post(
        id: '',
        userId: widget.userId,
        userName: widget.userName,
        userProfileImageUrl: widget.userProfileImageUrl,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        commentCount: 0,
      );
      await PostService().createPost(post);
      setState(() {
        _success = true;
        _feedback = 'Post published!';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onPostCreated();
    } catch (e) {
      setState(() {
        _feedback = 'Failed to publish post.';
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double popinHeight = MediaQuery.of(context).size.height * 0.75;
    final bool canPost = _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: popinHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height:
                      20), // Padding top pour éviter que le titre ne soit collé
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Create a post',
                  style: context.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Be respectful, you are responsible for your words. Any offensive content will result in a permanent ban from the app.',
                  style: context.bodyMedium.copyWith(
                    color: context.errorColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                minLines: 1,
                maxLines: 2,
                style: context.bodyLarge,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: context.bodyLarge.copyWith(color: context.grey500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _titleError ? 'Title is required' : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  filled: true,
                  fillColor: context.grey100,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  minLines: 5,
                  maxLines: 10,
                  style: context.bodyLarge,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Your message...',
                    hintStyle:
                        context.bodyLarge.copyWith(color: context.grey500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    errorText: _contentError ? 'Content is required' : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    filled: true,
                    fillColor: context.grey100,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_feedback != null)
                Text(
                  _feedback!,
                  style: context.bodyMedium.copyWith(
                    color: _success ? context.successColor : context.errorColor,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: canPost ? Colors.white : context.grey500,
                    ),
                    onPressed: canPost ? _submit : null,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      elevation: 0,
                    ),
                    tooltip: 'Post',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
