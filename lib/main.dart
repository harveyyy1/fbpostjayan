import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebook Post App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _subtextController = TextEditingController();
  Uint8List? _imageBytes;
  List posts = [];

  final _logger = Logger('PostPage');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _createPost() async {
    if (_imageBytes == null || _subtextController.text.isEmpty) {
      _logger.warning('Image or Subtext is missing');
      return;
    }

    final uri = Uri.parse('http://localhost:3000/api/posts');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        _imageBytes!,
        filename: 'upload.jpg',
      ),
    );

    request.fields['subtext'] = _subtextController.text;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _getPosts();
        setState(() {
          _imageBytes = null;
          _subtextController.clear();
        });
        _logger.info('Post created successfully');
      } else {
        _logger.severe('Failed to create post. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error during post creation: $e');
    }
  }

  Future<void> _getPosts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/posts'));

      if (response.statusCode == 200) {
        setState(() {
          posts = json.decode(response.body);
        });
      } else {
        _logger.severe('Failed to load posts. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('facebook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _subtextController,
                decoration: const InputDecoration(labelText: 'Write a caption...'),
              ),
              const SizedBox(height: 16),
              _imageBytes == null
                  ? IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: _pickImage,
                    )
                  : Image.memory(_imageBytes!, height: 200),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createPost,
                child: const Text('Create Post'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Recent Posts', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(posts[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(post) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.jpg'), // Replace with actual image
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('John Harvey Jayan', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('March 15, 2025', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post['subtext']),
            const SizedBox(height: 10),
            if (post['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'http://localhost:3000/uploads/${post['image']}',
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.thumb_up_alt, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text('177'),
                  ],
                ),
                const Text('95 😠  •  42 Comments • 5 Shares'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Icon(Icons.thumb_up_alt_outlined),
                Icon(Icons.comment_outlined),
                Icon(Icons.share_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
