import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
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
  List clusters = [];
  List trend = [];
  Map<String, int> sentimentCounts = {
    "Positive": 0,
    "Negative": 0,
    "Neutral": 0,
  };

  Future<void> fetchRedditPosts() async {
    final response = await http.get(
      Uri.parse('https://reddit-ai-demo.onrender.com/reddit/flutterdev'),
    );
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body)['posts'];
      });
      analyzeAllPosts();
    }
  }

  Future<void> analyzeAllPosts() async {
    for (var post in posts) {
      String sentiment = await analyzeSentiment(post['title']);
      setState(() {
        sentimentCounts[sentiment] = (sentimentCounts[sentiment] ?? 0) + 1;
      });
    }
  }

  Future<String> analyzeSentiment(String text) async {
    final response = await http.post(
      Uri.parse('https://reddit-ai-demo.onrender.com/analyze_sentiment'),
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

  Future<void> fetchTopicClusters() async {
    final response = await http.get(
      Uri.parse(
        'https://reddit-ai-demo.onrender.com/cluster_topics/flutterdev',
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        clusters = json.decode(response.body)['clusters'];
      });
    }
  }

  Future<void> fetchTrendPrediction() async {
    final response = await http.get(
      Uri.parse('https://reddit-ai-demo.onrender.com/predict_trend/flutterdev'),
    );
    if (response.statusCode == 200) {
      setState(() {
        trend = json.decode(response.body)['trend'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRedditPosts();
    fetchTopicClusters();
    fetchTrendPrediction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reddit AI App')),
      body: Column(
        children: [
          Container(height: 200, child: buildPieChart()),
          Container(height: 200, child: buildTrendChart()),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post['title']),
                  subtitle: Text('Upvotes: ${post['ups']}'),
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

  Widget buildTrendChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots:
                trend
                    .map(
                      (t) => FlSpot(
                        DateTime.parse(
                          t['ds'],
                        ).millisecondsSinceEpoch.toDouble(),
                        t['yhat'],
                      ),
                    )
                    .toList(),
            isCurved: true,
          ),
        ],
      ),
    );
  }
}
