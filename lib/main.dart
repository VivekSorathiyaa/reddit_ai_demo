import 'dart:convert';
import 'dart:developer';

import 'package:fl_chart/fl_chart.dart'; // For visualizations
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(RedditApp());
}

class RedditApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reddit AI App',
      theme: ThemeData.dark(),
      home: RedditHomePage(),
    );
  }
}

class RedditHomePage extends StatefulWidget {
  @override
  _RedditHomePageState createState() => _RedditHomePageState();
}

class _RedditHomePageState extends State<RedditHomePage> {
  List posts = [];
  Map<String, int> sentimentCounts = {
    'Positive': 0,
    'Negative': 0,
    'Neutral': 0,
  };

  Future<void> fetchRedditPosts() async {
    final response = await http.get(
      Uri.parse('https://www.reddit.com/r/flutterdev/top.json?limit=10'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        posts = data['data']['children'];
      });
      analyzeAllPosts();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> analyzeAllPosts() async {
    for (var post in posts) {
      String sentiment = await analyzeSentiment(post['data']['title']);
      setState(() {
        sentimentCounts[sentiment] = (sentimentCounts[sentiment] ?? 0) + 1;
      });
    }
  }

  Future<String> analyzeSentiment(String text) async {
    log("------analyzeSentiment------$text");
    final response = await http.post(
      Uri.parse(
        'https://reddit-ai-demo.onrender.com/analyze',
      ), // Update with your deployed API
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['sentiment'];
    } else {
      return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRedditPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reddit AI App')),
      body: Column(
        children: [
          Container(height: 200, child: buildPieChart()),
          Expanded(
            child:
                posts.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index]['data'];
                        return FutureBuilder(
                          future: analyzeSentiment(post['title']),
                          builder: (context, snapshot) {
                            String sentiment = 'Analyzing...';
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              sentiment = snapshot.data as String;
                            }
                            return ListTile(
                              title: Text(post['title']),
                              subtitle: Text(
                                'Upvotes: ${post['ups']} Sentiment: $sentiment',
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget buildPieChart() {
    return PieChart(
      PieChartData(
        sections:
            sentimentCounts.entries.map((entry) {
              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: entry.key,
              );
            }).toList(),
      ),
    );
  }
}
