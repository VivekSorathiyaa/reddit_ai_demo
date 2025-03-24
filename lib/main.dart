import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RedditAnalysisScreen(),
    );
  }
}

class RedditAnalysisScreen extends StatefulWidget {
  @override
  _RedditAnalysisScreenState createState() => _RedditAnalysisScreenState();
}

class _RedditAnalysisScreenState extends State<RedditAnalysisScreen> {
  List<dynamic> posts = [];
  bool isLoading = false;
  String subreddit = "technology";

  Future<void> fetchRedditData() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      'http://your-backend-url/fetch_reddit?subreddit=$subreddit&limit=10',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRedditData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reddit AI Analysis"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    elevation: 4,
                    child: ListTile(
                      title: Text(post['title']),
                      subtitle: Text(
                        "Sentiment: ${post['transformer_sentiment']}",
                      ),
                      trailing: Text("Score: ${post['score']}"),
                    ),
                  );
                },
              ),
    );
  }
}
