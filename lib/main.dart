import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(RedditApp());
}

class RedditApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Reddit AI App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purpleAccent,
        hintColor: Colors.deepOrangeAccent,
        buttonTheme: ButtonThemeData(buttonColor: Colors.purpleAccent),
      ),
      home: RedditDataScreen(),
    );
  }
}

class RedditController extends GetxController {
  var isLoading = false.obs;
  var redditPosts = <dynamic>[].obs;
  var query = "".obs;
  var page = 1.obs;
  var limit = 10.obs;

  Timer? _debounce;

  Future<void> fetchRedditData(
    String subreddit,
    int limit, {
    int page = 1,
  }) async {
    isLoading(true);

    final url = Uri.parse(
      "https://reddit-ai-demo.onrender.com/fetch_reddit?subreddit=$subreddit&limit=$limit&page=$page",
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        redditPosts.value = data;
      } else {
        print("Failed to fetch data: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching Reddit data: $error");
    } finally {
      isLoading(false);
    }
  }

  void searchRedditData() {
    if (query.isNotEmpty) {
      fetchRedditData(query.value, limit.value, page: page.value);
    }
  }

  void _onSearchChanged(String value) {
    query.value = value;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchRedditData();
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}

class RedditDataScreen extends StatelessWidget {
  final RedditController controller = Get.put(RedditController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reddit Data'),
        centerTitle: true,
        elevation: 10,
        shadowColor: Colors.purpleAccent,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: controller._onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search Reddit...',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(
                      TrendPredictionScreen(query: controller.query.value),
                    );
                  },
                  icon: Icon(Icons.trending_up),
                  label: Text('Prediction'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            Obx(() {
              if (controller.isLoading.value)
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purpleAccent,
                      ),
                    ),
                  ),
                );
              else
                return Expanded(
                  child:
                      controller.redditPosts.isEmpty
                          ? Center(
                            child: Text(
                              'No posts found',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                          : ListView.builder(
                            itemCount: controller.redditPosts.length,
                            itemBuilder: (context, index) {
                              var post = controller.redditPosts[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      post["title"],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Sentiment: ${post["sentiment"]}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    trailing: Text(
                                      'Score: ${post["score"]}',
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                    onTap: () {
                                      if (post["media"] != null) {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => AlertDialog(
                                                title: Text('Media Preview'),
                                                content: Image.network(
                                                  post["media"],
                                                ),
                                              ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                );
            }),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     ElevatedButton(
            //       onPressed: () {
            //         if (controller.page.value > 1) {
            //           controller.page.value--;
            //           controller.fetchRedditData(
            //             controller.query.value,
            //             controller.limit.value,
            //             page: controller.page.value,
            //           );
            //         }
            //       },
            //       child: Text('Previous'),
            //     ),
            //     SizedBox(width: 20),
            //     ElevatedButton(
            //       onPressed: () {
            //         controller.page.value++;
            //         controller.fetchRedditData(
            //           controller.query.value,
            //           controller.limit.value,
            //           page: controller.page.value,
            //         );
            //       },
            //       child: Text('Next'),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class TrendPredictionScreen extends StatefulWidget {
  final String query;

  TrendPredictionScreen({required this.query});

  @override
  _TrendPredictionScreenState createState() => _TrendPredictionScreenState();
}

class _TrendPredictionScreenState extends State<TrendPredictionScreen> {
  bool isLoading = false;
  List<dynamic> trendPrediction = [];

  Future<void> predictTrends(String subreddit, int days) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      "https://reddit-ai-demo.onrender.com/predict_trends?subreddit=$subreddit&days=$days",
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          trendPrediction = data;
        });
      } else {
        print("Failed to predict trends: ${response.statusCode}");
      }
    } catch (error) {
      print("Error predicting trends: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    predictTrends(
      widget.query,
      7,
    ); // Use the passed query for dynamic predictions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trend Prediction'),
        centerTitle: true,
        elevation: 10,
        shadowColor: Colors.purpleAccent,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.purpleAccent,
                    ),
                  ),
                ),
              ),
            Expanded(
              child:
                  trendPrediction.isEmpty && !isLoading
                      ? Center(
                        child: Text(
                          'No predictions available',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                      : ListView.builder(
                        itemCount: trendPrediction.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Date: ${trendPrediction[index]["ds"]}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  'Predicted Score: ${trendPrediction[index]["yhat"]}, Lower Bound: ${trendPrediction[index]["yhat_lower"]}, Upper Bound: ${trendPrediction[index]["yhat_upper"]}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
