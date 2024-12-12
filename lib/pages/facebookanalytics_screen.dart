import 'dart:convert';
import 'package:dotphi_seo_app/pages/seo_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'facebook_screens/contentfeed_screen.dart';
import 'facebook_screens/engagement_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String accessToken;

  const DashboardScreen({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  int? userId;
  String? pageName;
  String? pageId;
  String? pageAccessToken;
  List<Map<String, dynamic>> pages = []; // List to store pages
  String? selectedPageName;
  String? selectedPageId;
  int numberOfPosts = 0;
  int pageViews = 0; // Local variable to store page views
  int totalReactions=0;
  int totalEngagements = 0; // Variable to store the total engagement count
  double totalEngagementRate = 0;
  int totalImpressions = 0;
  double totalVVR = 0.0;
  int totalFollowers=0;
  int postClicks=0;
  late List<dynamic> posts;
  int totalOrganicImpressions = 0;
  int totalUniqueImpressions=0;
  int totalPostsCount=0;




  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://graph.facebook.com/v12.0/me?fields=id,name&access_token=${widget.accessToken}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          userName = data['name'];
          userId = int.tryParse(data['id'].toString()) ?? 0;
        });

        // Fetch pages after getting user details
        await _fetchPageList();
      } else {
        throw Exception("Failed to fetch user details");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user details: $e")),
      );
    }
  }

  Future<void> _fetchPageList() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://graph.facebook.com/v12.0/me/accounts?access_token=${widget.accessToken}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            pages = List<Map<String, dynamic>>.from(data['data']);
            print(pages);
          });
        } else {
          throw Exception("No pages found for this user");
        }
      } else {
        throw Exception("Failed to fetch pages");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching page list: $e")),
      );
    }
  }

  Future<void> _fetchSelectedPageDetails(String pageId, String accessToken) async {
    try {
      // Fetch posts and metrics for the selected page
      await getNumberOfPosts(pageId, accessToken);
      await fetchPageViewsForToday(pageId, accessToken);
      await fetchTotalReactions(pageId, accessToken);
      await fetchTotalEngagements(pageId, accessToken);
      await fetchTotalEngagementRate(pageId, accessToken);
      await fetchOrganicReachRate(pageId, accessToken);
      await fetchPagePosts(pageId, accessToken);
      await fetchPostsAndCalculateImpressions(pageId, accessToken);
      await fetchFollowerCount(pageId, accessToken);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching selected page details: $e")),
      );
    }
  }

  Future<void> getNumberOfPosts(String pageId, String pageAccessToken) async {
    final DateTime now = DateTime.now();
    final DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));

    final String sinceDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
    final String untilDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final String url =
        'https://graph.facebook.com/$pageId/posts?access_token=$pageAccessToken&since=$sinceDate&until=$untilDate';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            numberOfPosts = data['data'].length; // Store the count of posts
          });
          print('Number of posts in the last 30 days: $numberOfPosts');
        } else {
          setState(() {
            numberOfPosts = 0;
          });
        }
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        numberOfPosts = 0;
      });
    }
  }

  Future<void> fetchPageViewsForToday(String pageId, String accessToken) async {
    try {
      // Get today's date
      final today = DateTime.now();
      final formattedToday =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      print(formattedToday);

      // Build the API URL
      final url =
          'https://graph.facebook.com/v21.0/$pageId/insights/page_views_total?since=$formattedToday&until=$formattedToday&period=month&access_token=$accessToken';

      // Make the API request
      final response = await http.get(Uri.parse(url));

      // Check the response status code
      if (response.statusCode == 200) {
        // Parse the response body
        final data = jsonDecode(response.body);
        print('Raw response data: $data'); // Log raw data for debugging

        // Validate the structure of the response
        if (data.containsKey('data') && (data['data'] as List).isNotEmpty) {
          final pageViewData = data['data'][0]; // First data object

          if (pageViewData.containsKey('values') &&
              (pageViewData['values'] as List).isNotEmpty) {
            final pageViews = pageViewData['values'][0]['value'];
            print('Page Views for today ($formattedToday): $pageViews');
            return;
          }
        }

        // Log if no data found
        print('No data found for page views on $formattedToday.');
      } else {
        print(
            'Failed to fetch data. HTTP Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching page views: $e');
    }
  }

  Future<int> fetchTotalReactions(String pageId, String accessToken) async {
    // int totalReactions = 0; // Define a local variable to store the total reactions.

    // Dynamically calculate 'since' and 'until' dates
    final now = DateTime.now();
    final lastMonthSameDay = DateTime(now.year, now.month - 1, now.day);
    final today = now;

    final since = lastMonthSameDay.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
    final until = today.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD

    // Construct the API URL
    String url =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=reactions.summary(total_count)&since=$since&until=$until&access_token=$accessToken';

    try {
      while (true) {
        // Make the API request
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Parse the data to calculate total reactions
          final posts = data['data'] as List<dynamic>;
          for (var post in posts) {
            final reactionsSummary = post['reactions']?['summary'];
            if (reactionsSummary != null) {
              setState(() {
                totalReactions += reactionsSummary['total_count'] as int;
                print('Total reactions');
                print(totalReactions);
              });
            }
          }

          // Check if there's more data to paginate
          final paging = data['paging'];
          if (paging != null && paging['next'] != null) {
            // Update the URL to fetch the next page
            url = paging['next'];
          } else {
            break; // No more pages
          }
        } else {
          throw Exception('Failed to fetch data: ${response.body}');
        }
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }

    return totalReactions; // Return the total reactions.
  }


  Future<int> fetchReactionsCount(String pageId, String accessToken, String since, String until) async {
    final url =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=reactions.summary(total_count)&since=$since&until=$until&access_token=$accessToken';
    int totalReactions = 0;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['data'] as List;
        for (var post in posts) {
          final reactionsCount = (post['reactions']?['summary']?['total_count'] ?? 0) as int;
          totalReactions += reactionsCount;
        }
      } else {
        print('Failed to fetch reactions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching reactions: $e');
    }

    return totalReactions;
  }

  Future<int> fetchCommentsCount(String pageId, String accessToken, String since, String until) async {
    final url =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=comments.summary(total_count)&since=$since&until=$until&access_token=$accessToken';
    int totalComments = 0;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['data'] as List;
        for (var post in posts) {
          final commentsCount = (post['comments']?['summary']?['total_count'] ?? 0) as int;
          totalComments += commentsCount;
        }
      } else {
        print('Failed to fetch comments: ${response.body}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }

    return totalComments;
  }
  Future<int> fetchSharesCount(String pageId, String accessToken, String since, String until) async {
    final url =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=shares.summary(total_count)&since=$since&until=$until&access_token=$accessToken';
    int totalShares = 0;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        final posts = data['data'] as List;

        // Loop through all the posts and check if shares count is available
        for (var post in posts) {
          // Check if 'shares' field exists and contains 'summary' with 'total_count'
          if (post.containsKey('shares') && post['shares'].containsKey('count')) {
            int sharesCount = post['shares']['count'] ?? 0;
            totalShares += sharesCount;
            print('Shares Count for post: $sharesCount');
          }
        }

        print('Total Shares: $totalShares');
      } else {
        print('Failed to fetch shares: ${response.body}');
      }
    } catch (e) {
      print('Error fetching shares: $e');
    }

    return totalShares;
  }

  Future<int> fetchTotalEngagements(String pageId, String accessToken) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1); // Start of the month
    final since = startOfMonth.toIso8601String().split('T')[0]; // Start date: YYYY-MM-DD
    final until = now.toIso8601String().split('T')[0]; // End date: Today's date

    try {
      // final reactionsCount = await fetchReactionsCount(pageId, accessToken, since, until);
      final commentsCount = await fetchCommentsCount(pageId, accessToken, since, until);
      final sharesCount = await fetchSharesCount(pageId, accessToken, since, until);
       setState(() {
         totalEngagements = totalReactions + commentsCount + sharesCount;
       });
      print('Total Engagements: $totalEngagements');
      return totalEngagements;
    } catch (e) {
      print('Error fetching total engagements: $e');
      return 0;
    }
  }

  Future<double> fetchTotalEngagementRate(String pageId, String accessToken) async {
    // Dynamically calculate 'since' and 'until' dates for the current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1); // Start of the month
    final since = startOfMonth.toIso8601String().split('T')[0]; // Start date: YYYY-MM-DD
    final until = now.toIso8601String().split('T')[0]; // End date: Today's date

    // Construct the API URLs for reactions, comments, shares, and reach
    final reactionsUrl =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=reactions.summary(total_count),comments.summary(total_count),reach&since=$since&until=$until&access_token=$accessToken';
    final sharesUrl =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=shares.summary(total_count)&since=$since&until=$until&access_token=$accessToken';

    int totalEngagements = 0; // To store the total engagements (reactions + comments + shares)
    // To store the average Engagement Rate (ER)
    int totalPosts = 0; // To track the number of posts processed

    try {
      // Fetch Reactions, Comments, and Reach Data
      final reactionsResponse = await http.get(Uri.parse(reactionsUrl));
      if (reactionsResponse.statusCode == 200) {
        final reactionsData = json.decode(reactionsResponse.body);
        final posts = reactionsData['data'] as List;

        // Loop through posts and calculate total engagements
        for (var post in posts) {
          // Null check and cast to int for reactionsCount
          int reactionsCount = (post['reactions'] != null && post['reactions']['summary'] != null)
              ? (post['reactions']['summary']['total_count'] ?? 0).toInt()
              : 0;

          // Null check and cast to int for commentsCount
          int commentsCount = (post['comments'] != null && post['comments']['summary'] != null)
              ? (post['comments']['summary']['total_count'] ?? 0).toInt()
              : 0;

          // Get the reach for the post
          int reach = post['reach'] ?? 0;

          if (reach > 0) {
            // Calculate Public Engagements
            int publicEngagements = reactionsCount + commentsCount;

            // Calculate the Engagement Rate for this post
            double postEngagementRate = (publicEngagements / reach) * 100;

            // Add the post's engagement rate to the total
            totalEngagementRate += postEngagementRate;
            totalPosts++;
          }

          // Add the reactions, comments counts to totalEngagements
          totalEngagements += (reactionsCount + commentsCount);
        }
      } else {
        print('Failed to fetch reactions and comments: ${reactionsResponse.body}');
      }

      // Fetch Shares Data
      final sharesResponse = await http.get(Uri.parse(sharesUrl));
      if (sharesResponse.statusCode == 200) {
        final sharesData = json.decode(sharesResponse.body);
        final posts = sharesData['data'] as List;

        // Loop through posts and add shares counts
        for (var post in posts) {
          // Null check and cast to int for sharesCount
          int sharesCount = (post['shares'] != null && post['shares']['summary'] != null)
              ? (post['shares']['summary']['total_count'] ?? 0).toInt()
              : 0;

          // Add shares count to totalEngagements
          totalEngagements += sharesCount;

          // Get the reach for the post
          int reach = post['reach'] ?? 0;

          if (reach > 0) {
            // Calculate Public Engagements for shares
            int publicEngagements = sharesCount;

            // Calculate the Engagement Rate for shares
            double postEngagementRate = (publicEngagements / reach) * 100;

            // Add the post's engagement rate to the total
            totalEngagementRate += postEngagementRate;
            totalPosts++;
          }
        }
      } else {
        print('Failed to fetch shares: ${sharesResponse.body}');
      }

      // Calculate the average Engagement Rate (ER) across all posts
      if (totalPosts > 0) {
        totalEngagementRate = totalEngagementRate / totalPosts;
      }

    } catch (e) {
      print('Error: $e');
      rethrow;
    }

    // Return the total engagements (reactions, comments, shares) and Engagement Rate (ER)
    print('Total Engagements: $totalEngagements');
    print('Average Engagement Rate: $totalEngagementRate%');
    return totalEngagementRate; // You can also return totalEngagements if needed
  }

  Future<int> fetchTotalPostImpressions(String pageId, String accessToken, String since, String until) async {
    // Construct the API URL to fetch post impressions
    String url =
        'https://graph.facebook.com/v17.0/$pageId/posts?fields=metrics(post_impressions)&since=$since&until=$until&access_token=$accessToken';

    

    try {
      // Make the API request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['data'] as List;

        // Loop through each post and sum up the impressions
        for (var post in posts) {
          final metrics = post['metrics'] as List;

          // Find the 'post_impressions' metric
          final impressionsData = metrics.firstWhere(
                  (metric) => metric['name'] == 'post_impressions', orElse: () => null);

          if (impressionsData != null) {
            // Extract the value of impressions
            int impressionsValue = impressionsData['values'][0]['value'] ?? 0;
            totalImpressions += impressionsValue;
          }
        }
      } else {
        print('Failed to fetch post impressions: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }

    return totalImpressions;
  }

  Future<double> fetchOrganicReachRate(String pageId, String accessToken) async {
    // Calculate the 'since' and 'until' dates
    DateTime today = DateTime.now();
    DateTime oneMonthAgo = today.subtract(Duration(days: 30));

    // Format the dates in the required format (YYYY-MM-DD)
    String since = "${oneMonthAgo.year}-${oneMonthAgo.month.toString().padLeft(2, '0')}-${oneMonthAgo.day.toString().padLeft(2, '0')}";
    String until = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Fetch followers count
    String followersUrl = 'https://graph.facebook.com/v17.0/$pageId?fields=followers_count&access_token=$accessToken';
    int followersCount = 0;

    try {
      final followersResponse = await http.get(Uri.parse(followersUrl));
      if (followersResponse.statusCode == 200) {
        final followersData = json.decode(followersResponse.body);
        followersCount = followersData['followers_count'] ?? 0;
      } else {
        print('Failed to fetch followers count: ${followersResponse.body}');
        return 0.0; // Return 0 if we can't fetch followers
      }

      // Construct the API URL to fetch post insights
      String postsUrl =
          'https://graph.facebook.com/v17.0/$pageId/posts?fields=insights.metric(organic_reach)&since=$since&until=$until&access_token=$accessToken';

      final response = await http.get(Uri.parse(postsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['data'] as List;

        double totalPostORR = 0.0;
        int postCount = 0;

        // Loop through each post and calculate ORR
        for (var post in posts) {
          final insights = post['insights']['data'] as List;
          final organicReachData = insights.firstWhere(
                  (metric) => metric['name'] == 'organic_reach', orElse: () => null);

          if (organicReachData != null && followersCount > 0) {
            final organicReach = organicReachData['values'][0]['value'] ?? 0;

            // Calculate ORR for this post
            double postORR = (organicReach / followersCount) * 100;
            totalPostORR += postORR;
            postCount++;
          }
        }

        // Calculate the average ORR
        if (postCount > 0) {
          return totalPostORR / postCount;
        } else {
          print('No posts found in the given date range.');
          return 0.0;
        }
      } else {
        print('Failed to fetch post insights: ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<int> fetchVideoViewCount(String pageId, String accessToken) async {
    // Construct the URL to fetch the list of videos from the page
    String url =
        'https://graph.facebook.com/v17.0/$pageId/videos?access_token=$accessToken';

    int totalViews = 0;

    try {
      // Make the GET request to fetch the list of videos
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = data['data'] as List;

        // Loop through each video and fetch the insights for video views
        for (var video in videos) {
          final videoId = video['id'];

          // Fetch insights for the video to get the views count
          final insightsUrl =
              'https://graph.facebook.com/v17.0/$videoId/insights?metric=post_video_views&access_token=$accessToken';
          final insightsResponse = await http.get(Uri.parse(insightsUrl));

          if (insightsResponse.statusCode == 200) {
            final insightsData = json.decode(insightsResponse.body);
            final insights = insightsData['data'] as List;

            // Extract the video views count from the insights
            final viewsData = insights.firstWhere(
                    (metric) => metric['name'] == 'post_video_views',
                orElse: () => null);

            if (viewsData != null) {
              int viewsValue = viewsData['values'][0]['value'] ?? 0;
              totalViews += viewsValue;
            }
          } else {
            print('Failed to fetch insights for video $videoId: ${insightsResponse.body}');
          }
        }
      } else {
        print('Failed to fetch videos: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }

    return totalViews;
  }

  Future<double> fetchVideoViewRate(String pageId, String accessToken) async {
    // Construct the URL to fetch the list of videos from the page
    String url =
        'https://graph.facebook.com/v17.0/$pageId/videos?access_token=$accessToken';


    int videoCount = 0;

    try {
      // Make the GET request to fetch the list of videos
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = data['data'] as List;

        // Loop through each video and fetch the insights for video views and reach
        for (var video in videos) {
          final videoId = video['id'];

          // Fetch insights for the video to get the views and reach
          final insightsUrl =
              'https://graph.facebook.com/v17.0/$videoId/insights?metric=video_views_3s,reach&access_token=$accessToken';
          final insightsResponse = await http.get(Uri.parse(insightsUrl));

          if (insightsResponse.statusCode == 200) {
            final insightsData = json.decode(insightsResponse.body);
            final insights = insightsData['data'] as List;

            // Extract the video views (3-seconds) and reach from the insights
            final viewsData = insights.firstWhere(
                    (metric) => metric['name'] == 'video_views_3s',
                orElse: () => null);
            final reachData = insights.firstWhere(
                    (metric) => metric['name'] == 'reach',
                orElse: () => null);

            if (viewsData != null && reachData != null) {
              final viewsValue = viewsData['values'][0]['value'] ?? 0;
              final reachValue = reachData['values'][0]['value'] ?? 0;

              if (reachValue > 0) {
                // Calculate the 3-sec VVR for this video
                final videoVVR = (viewsValue / reachValue) * 100;
                totalVVR += videoVVR;
                videoCount++;
              }
            }
          } else {
            print('Failed to fetch insights for video $videoId: ${insightsResponse.body}');
          }
        }
      } else {
        print('Failed to fetch videos: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }

    // Calculate the average VVR if there are videos to average
    if (videoCount > 0) {
      return totalVVR / videoCount;
    } else {
      return 0.0;
    }
  }


  Future<void> fetchFollowerCount(String pageId, String accessToken) async {
    final String url =
        'https://graph.facebook.com/v17.0/$pageId?fields=followers_count&access_token=$accessToken';

    try {
      // Make the API request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int followersCount = data['followers_count'] ?? 0;

        // Use setState to update the followers count in the UI
        setState(() {
          totalFollowers = followersCount;
        });

        print('Total Followers: $totalFollowers');
      } else {
        print('Failed to fetch followers count: ${response.body}');
        setState(() {
          totalFollowers = 0; // In case of failure, set followers to 0
        });
      }
    } catch (e) {
      print('Error fetching followers count: $e');
      setState(() {
        totalFollowers = 0; // In case of an error, set followers to 0
      });
    }
  }

  Future<Map<String, dynamic>> fetchPostInsights(String postId, String accessToken) async {
    // Get today's date and the date one month before
    final today = DateTime.now();
    final oneMonthAgo = DateTime(today.year, today.month - 1, today.day);

    // Format dates for the API
    final formatter = DateFormat('yyyy-MM-dd');
    final sinceDate = formatter.format(oneMonthAgo);
    final untilDate = formatter.format(today);

    // Construct API URL
    final url =
        'https://graph.facebook.com/v21.0/$postId/insights?fields=insights.metric(post_clicks)&since=$sinceDate&until=$untilDate&access_token=$accessToken';

    try {
      // Make the API call
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse and return the JSON response
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch insights: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching insights: $e');
    }
  }

  Future<void> fetchPostClicks(String postId, String accessToken) async {

    final Uri url = Uri.parse(
      'https://graph.facebook.com/v21.0/$pageId/posts?fields=insights.metric(post_clicks)&since=2024-11-04&until=2024-12-04&access_token=$accessToken',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Loop through each post and extract the post_clicks value
        for (var post in data['data']) {
          final insights = post['insights']['data'];
          for (var insight in insights) {
            if (insight['name'] == 'post_clicks') {
              postClicks = insight['values'][0]['value'];
              print('Post Clicks: $postClicks');
            }
          }
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<List<Map<String, dynamic>>> fetchPagePosts(String pageId, String accessToken) async {
    String sinceDate = DateTime.now().subtract(Duration(days: 30)).toIso8601String(); // One month ago
    String untilDate = DateTime.now().toIso8601String(); // Current date
    final String url = 'https://graph.facebook.com/v17.0/$pageId/posts'
        '?fields=full_picture,message,created_time,insights.metric(post_impressions,post_impressions_unique),likes.summary(true),shares.summary(true)'
        '&since=$sinceDate'
        '&until=$untilDate'
        '&access_token=$accessToken';

    List<Map<String, dynamic>> allPosts = [];
    String? nextUrl = url;

    try {
      while (nextUrl != null) {
        final response = await http.get(Uri.parse(nextUrl));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          posts = data['data'];
          print(posts);

          // Append current batch of posts to the list
          allPosts.addAll(posts.cast<Map<String, dynamic>>());

          // Get the next page URL if it exists
          nextUrl = data['paging']?['next'];
        } else {
          throw Exception('Failed to fetch posts: ${response.body}');
        }
      }
    } catch (e) {
      print('Error fetching posts: $e');
    }

    return allPosts;
  }

  Future<void> fetchPostsAndCalculateImpressions(String pageId, String accessToken) async {
    // Calculate `since` and `until` dates
    final DateTime today = DateTime.now();
    final DateTime oneMonthAgo = DateTime(today.year, today.month - 1, today.day);
    final String since = oneMonthAgo.toIso8601String().split('T').first;
    final String until = today.toIso8601String().split('T').first;

    final String url =
        'https://graph.facebook.com/v21.0/$pageId/posts?fields=insights.metric(post_impressions_organic,post_impressions_organic_unique)&since=$since&until=$until&period=month';

    try {
      final response = await http.get(Uri.parse('$url&access_token=$accessToken'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Reset totals before calculation
        setState(() {
          totalOrganicImpressions = 0;
          totalUniqueImpressions = 0;
          totalPostsCount = 0; // New variable to store post count
        });

        // Calculate total impressions and post count
        if (data['data'] != null) {
          for (var post in data['data']) {
            // Increment the post count
            setState(() {
              totalPostsCount += 1;
            });

            if (post['insights'] != null && post['insights']['data'] != null) {
              for (var metric in post['insights']['data']) {
                if (metric['name'] == 'post_impressions_organic') {
                  // Add to totalOrganicImpressions
                  final num value = metric['values'][0]['value'];
                  setState(() {
                    totalOrganicImpressions += value.toInt();
                  });
                } else if (metric['name'] == 'post_impressions_organic_unique') {
                  // Add to totalUniqueImpressions
                  final num value = metric['values'][0]['value'];
                  setState(() {
                    totalUniqueImpressions += value.toInt();
                  });
                }
              }
            }
          }
        }

        print('Total Organic Impressions: $totalOrganicImpressions');
        print('Total Unique Impressions: $totalUniqueImpressions');
        print('Total Posts Count: $totalPostsCount'); // Print the post count
      } else {
        print('Failed to fetch posts. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  void _logoutFacebook(BuildContext context) async {
    try {
      // Log out from Facebook
      await FacebookAuth.instance.logOut();

      // Optionally, you can show a snackbar or navigate to another screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out from Facebook")),
      );

      // Navigate to a different screen, if needed (e.g., login screen)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SignInScreen()));
    } catch (e) {
      print("Error during Facebook logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error logging out from Facebook")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Material(
          elevation: 8.0, // Set the desired elevation value
          shadowColor: Colors.black.withOpacity(0.3), // Optional: customize shadow color
          borderRadius: BorderRadius.circular(10.0), //
          child: Container(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/facebook.png',
                  height: 25,
                  width: 25,
                ),
                const SizedBox(width: 5),
                // If the page is selected, show the selectedPageName
                // if (selectedPageName != null)
                //   Text(
                //     selectedPageName ?? "Select page", // Show default if no pages
                //     style: const TextStyle(
                //         fontSize: 16, color: Colors.black, fontFamily: 'Poppins'),
                //   ),
                // If the pages list is not empty, show the DropdownButton
                if (pages.isNotEmpty) ...[
                  // Display the currently selected page or default text
                  // Text(
                  //   selectedPageName ?? "Select Page", // Default text if no page is selected
                  //   style: const TextStyle(
                  //     fontSize: 16,
                  //     color: Colors.black,
                  //     fontFamily: 'Poppins',
                  //   ),
                  // ),
                  // DropdownButton to select a page
                  DropdownButton<String>(
                    value: selectedPageName, // Initially null to display the hint
                    hint: const Text(
                      'Select Page', // Placeholder text
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                    underline: const SizedBox(), // Remove the underline
                    onChanged: (String? newPageName) {
                      if (newPageName != null) {
                        setState(() {
                          selectedPageName = newPageName; // Update selected page name
                          final selectedPage = pages.firstWhere(
                                (page) => page['name'] == newPageName,
                          );
                          selectedPageId = selectedPage['id'];
                          pageAccessToken = selectedPage['access_token'];
                        });

                        // Call the method to fetch metrics for the selected page
                        // getNumberOfPosts(selectedPageId!, pageAccessToken!);
                        _fetchSelectedPageDetails(selectedPageId!, pageAccessToken!);
                      }
                    },
                    items: pages.map<DropdownMenuItem<String>>((page) {
                      return DropdownMenuItem<String>(
                        value: page['name'],
                        child: Text(page['name'] ?? 'No name available'),
                      );
                    }).toList(),
                  ),
                ]

              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context), // Drawer as usual
      body: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0,top: 10.0),
              child: Text('Summary',style: TextStyle(
                color: Colors.blue.shade900,
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),),
            ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.42, // 80% of screen width
              height: MediaQuery.of(context).size.height * 0.30, // Set the desired height
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Post Impressions',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.blue.shade900,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.blue.shade900, // Line color
                      thickness: 2.0, // Line thickness

                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        totalOrganicImpressions.toString(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Organic Reach Rate (ORR)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.blue.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        (((totalUniqueImpressions/totalFollowers)*100)/numberOfPosts).toStringAsFixed(2).toString(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              width:  MediaQuery.of(context).size.width * 0.42, // 80% of screen width // Set the desired width
              height: MediaQuery.of(context).size.height * 0.30, // Set the desired height
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Followers',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.blue.shade900,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.blue.shade900, // Line color
                      thickness: 2.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        totalFollowers.toString(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )

      ],
        ),
      )
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header with margin from the top
          Container(
            color: Colors.blue.shade900,
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard, // Icon before the title
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        userName != null ? userName![0].toUpperCase() : "?",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userId != null ? "ID: $userId" : "",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
              height: 5), // Margin added between header and list items
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.summarize,
                  title: "Summary",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.content_paste_sharp,
                  title: "Content Feed",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ContentfeedScreen(posts: posts,selectedPageName:selectedPageName!)));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt,
                  title: "Growth & Audience",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.video_collection,
                  title: "Video Views",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.thumb_up,
                  title: "Engagement",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>EngagementScreen(numberOfPosts: numberOfPosts,selectedPageName:selectedPageName!,pageViews: pageViews,totalReactions: totalReactions,totalEngagements: totalEngagements,totalEngagementRate: totalEngagementRate, totalImpressions: totalImpressions, totalVVR: totalVVR,)));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.ads_click,
                  title: "Link Clicks",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(
              "Logout",
              style: TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            onTap: () {
              _logoutFacebook(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully!")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
        ),
      ),
      onTap: onTap,
    );
  }
}
