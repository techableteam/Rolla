import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  static const String baseUrl = 'http://98.84.126.74/api';
  String apiKey = 'cfdb0e89363c14687341dbc25d1e1d43';
  final logger = Logger();

  Future<Map<String, dynamic>> deleteTrip(int tripId) async {
    final url = Uri.parse('$baseUrl/trip/delete');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
        }),
      );
      if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data.containsKey('statusCode') && data.containsKey('message')) {
            return {
              "statusCode": data['statusCode'],
              "message": data['message'],
            };
          } else {
            throw Exception('Invalid response format: Missing expected keys');
          }
        } else {
          throw Exception('Request failed with status: ${response.statusCode}');
        }
    } catch (e) {
      logger.e("Error deleting trip: $e");
      throw Exception('Error deleting trip: $e');
    }
  }

  Future<Map<String, dynamic>> requestFollowPending (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/requestfollow');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> removeUserfollow (int userId, int followingId) async {
    logger.i(userId);
    logger.i(followingId);
    final url = Uri.parse('$baseUrl/user/removeUserfollow');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedTaged (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/tapviewed');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'tag_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> tappedFollowed (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/tapfollowedUser');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'followed_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedCommented (int userId, int commenterId) async {
    final url = Uri.parse('$baseUrl/user/commentviewed');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'commenter_id': commenterId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedliked (int userId, int likedid) async {
    final url = Uri.parse('$baseUrl/user/likedviewed');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'like_id': likedid,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewAcceptNotification (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/accpetViewed');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> requestFollowAccept (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/acceptfollow');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedFollowingNotification (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/viewedfollowingnotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      logger.i(response);
      throw Exception('Failed to follow user: ${response.statusCode}');
      
    }
  }

  Future<Map<String, dynamic>> clickedFollowingNotification (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/clickedFollowingNotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      logger.i(response);
      throw Exception('Failed to follow user: ${response.statusCode}');
      
    }
  }

  Future<Map<String, dynamic>> viewedPendingNotification (int userId, int pendingId) async {
    final url = Uri.parse('$baseUrl/user/viewedfollowPendingnotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'followpending_id': pendingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> clickedPendingNotification (int userId, int pendingId) async {
    final url = Uri.parse('$baseUrl/user/clickedFollowPendingNotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'followpending_id': pendingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedFollowedNotification (int userId, int followedId) async {
    final url = Uri.parse('$baseUrl/user/viewedfollowednotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'followed_id': followedId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        logger.e('Failed to mark as viewed: ${response.statusCode}, ${response.body}');
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> clickedFollowedNotification (int userId, int followedId) async {
    final url = Uri.parse('$baseUrl/user/clickedFollowedNotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'followed_id': followedId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        logger.e('Failed to mark as viewed: ${response.statusCode}, ${response.body}');
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> viewedTagNotification (int userId, int tagId) async {
    final url = Uri.parse('$baseUrl/user/viewedtagnotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'tag_id': tagId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> clickedTagNotification (int userId, int tagId) async {
    final url = Uri.parse('$baseUrl/user/clickedTagNotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'tag_id': tagId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedCommentNotification (int userId, int commentId) async {
    final url = Uri.parse('$baseUrl/user/viewedcommentnotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'commenter_id': commentId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> clickedCommentNotification (int userId, int commentId) async {
    final url = Uri.parse('$baseUrl/user/clickedCommentNotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'commenter_id': commentId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> viewedlikeNotification (int userId, int likeId) async {
    final url = Uri.parse('$baseUrl/user/viewedlikenotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'like_id': likeId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> clickedlikeNotification (int userId, int likeId) async {
    final url = Uri.parse('$baseUrl/user/clickedLikeNotification');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'like_id': likeId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> removePendingFollow (int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/removefollow');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> followUser(int userId, int followingId) async {
    final url = Uri.parse('$baseUrl/user/following');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'following_id': followingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> muteUser(int userId, int tripId) async {
    final url = Uri.parse('$baseUrl/trip/mute_user');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'trip_id': tripId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> blockUser(int userId, int blockId) async {
    final url = Uri.parse('$baseUrl/user/block');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'block_id': blockId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      logger.i(data);
      
      if (data.containsKey('statusCode') && data.containsKey('message') && data.containsKey('data')) {
        return {
          "statusCode": data['statusCode'],
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        throw Exception('Invalid response format: Missing expected keys');
      }
    } else {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> markDropinAsViewed({
    required int userId,
    required int dropinId,
  }) async {
    final url = Uri.parse('$baseUrl/droppin/viewed');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'droppin_id': dropinId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'statusCode': data['statusCode'],
        'message': data['message'],
        'data': data['data'],
      };
    } else {
      return {
        'statusCode': false,
        'message': 'Request failed with status ${response.statusCode}',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> markDropinWithNumberAsViewed({
    required int userId,
    required int dropinId,
    required int incrementNumber,
  }) async {
    final url = Uri.parse('$baseUrl/droppin/viewed');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'droppin_id': dropinId,
        'increment' : incrementNumber
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'statusCode': data['statusCode'],
        'message': data['message'],
        'data': data['data'],
      };
    } else {
      return {
        'statusCode': false,
        'message': 'Request failed with status ${response.statusCode}',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> fetchAllDropPinData() async {
    final url = Uri.parse('$baseUrl/droppin/data');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('status') && data.containsKey('data')) {
        return {
          "status": data['status'], // Returns status
          "data": List<Map<String, dynamic>>.from(
              data['data']) // Returns data as a list of maps
        };
      } else {
        throw Exception('Invalid response format: Missing status or data');
      }
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchTripData(int tripId) async {
    final url = Uri.parse(
        '$baseUrl/trip/trips/id?trip_id=$tripId'); // API Endpoint with trip_id as a query parameter

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('message') && data.containsKey('trips')) {
        return {
          "message": data['message'], // Returns message
          "trips": List<Map<String, dynamic>>.from(
              data['trips']) // Returns trips data as a list of maps
        };
      } else {
        throw Exception('Invalid response format: Missing message or trips');
      }
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchAllUserData() async {
    final url = Uri.parse('$baseUrl/user/all'); // API Endpoint

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Correct the condition
      if (data['message'] == "success" && data.containsKey('data')) {
        return {
          "status": data['statusCode'], // Ensure statusCode is correctly used
          "data": List<Map<String, dynamic>>.from(
              data['data']) // Ensure it's a List of Maps
        };
      } else {
        throw Exception('Invalid response format: Missing status or data');
      }
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllTrips() async {
    final url = Uri.parse('$baseUrl/trip/data');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['message'] == 'All trips retrieved successfully') {
        return List<Map<String, dynamic>>.from(data['trips']);
      } else {
        throw Exception('Failed to fetch trips: ${data['message']}');
      }
    } else {
      throw Exception('Failed to fetch trips: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchCarData() async {
    final url = Uri.parse('$baseUrl/car_types');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load car data');
      }
    } catch (e) {
      throw Exception('Error fetching car data: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': email, 'password': password}),
      );
      final Map<String, dynamic> parsedResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Unknown error occurred',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      logger.e('Error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again later.',
      };
    }
  }

  Future<String> getImageUrl(String base64) async {
    var url = Uri.parse('https://api.imgbb.com/1/upload');
    var response = await http.post(url, body: {
      'key': apiKey,
      'image': base64,
    });
    // logger.i(jsonDecode(response.body)['data']['url']);
    return jsonDecode(response.body)['data']['url'];
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String rollaUsername,
    required String hearRolla,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'rolla_username': rollaUsername,
          'hear_rolla': hearRolla,
        }),
      );

      // Debugging: Log the response
      logger.i('Response status: ${response.statusCode}');
      logger.i('Response body: ${response.body}');

      // Parse the response body
      final Map<String, dynamic> parsedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Registration successful
        return {
          'success': true,
          'message': parsedResponse['message'],
          'token': parsedResponse['token'],
          'userData': parsedResponse['userData'],
        };
      } else if (response.statusCode == 422) {
        // Handle validation errors
        List<String> errors = [];

        // Check for email errors
        if (parsedResponse.containsKey('email')) {
          errors.addAll(parsedResponse['email'].cast<String>());
        }

        // Check for rolla_username errors
        if (parsedResponse.containsKey('rolla_username')) {
          errors.addAll(parsedResponse['rolla_username'].cast<String>());
        }

        return {
          'success': false,
          'message':
              errors.join('\n'), // Combine all errors into a single string
        };
      } else {
        // Handle error responses
        return {
          'success': false,
          'message': parsedResponse['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      // Handle unexpected errors
      logger.i('Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> updateUser(
      {required int userId,
      required String firstName,
      required String lastName,
      required String rollaUsername,
      String? happyPlace,
      String? photo,
      String? bio,
      String? garage}) async {
    final url = Uri.parse('$baseUrl/user/update');

    // Prepare the request body
    final Map<String, dynamic> body = {
      "user_id": userId,
      "first_name": firstName,
      "last_name": lastName,
      "rolla_username": rollaUsername,
      if (happyPlace != null) "happy_place": happyPlace,
      if (photo != null) "photo": photo,
      if (bio != null) "bio": bio,
      if (garage != null) "garage": garage,
    };
    logger.i(body);

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      logger.i('Response status: ${response.statusCode}');
      logger.i('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Handle errors
        final errorResponse = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorResponse['message'] ?? 'Unknown error',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      // Handle exceptions
      logger.i('Error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again later.',
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchFollowers(int userId) async {
    final url = Uri.parse('$baseUrl/user/following_users?user_id=$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Failed to load followers: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load followers: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching followers: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> fetchNotificationUsers(int userId) async {
    final url = Uri.parse('$baseUrl/user/notification_users?id=$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['statusCode'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load followers: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load followers: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingFollowingUsers(int userId) async {
    final url = Uri.parse('$baseUrl/user/pending_following_users?user_id=$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['statusCode'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load followers: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load followers: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBlockUsers(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/user/block_users?user_id=$userId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else if (response.statusCode == 404){
        return [];
      } 
      
      else {
        throw Exception('Failed to load blocked users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching blocked users: $e');
    }
  }


  // Future<List<Map<String, dynamic>>> fetchFollowerTrip(int userId) async {
  //   final url = Uri.parse('$baseUrl/user/follwed_user/trips?user_id=$userId');

  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     if (data['statusCode'] == true) {
  //       return List<Map<String, dynamic>>.from(data['data']);
  //     } else {
  //       throw Exception('Failed to load followers: ${data['message']}');
  //     }
  //   } else {
  //     throw Exception('Failed to load followers: ${response.statusCode}');
  //   }
  // }

  Future<Map<String, dynamic>> fetchFollowerTrip(int userId) async {
    final url = Uri.parse('$baseUrl/user/follwed_user/trips?user_id=$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // logger.i(data);
      if (data['statusCode'] == true) {
        return {
          'userinfo': data['userinfo'],
          'trips': List<Map<String, dynamic>>.from(data['data']),
        };
      } else {
        throw Exception('Failed to load trips: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load trips: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFollowedUsers(int userId) async {
    logger.i(userId);
    final url = Uri.parse('$baseUrl/user/followed_users?id=$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );
    // logger.i(response);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['statusCode'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load followers: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load followers: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createTrip({
    required int userId,
    required String startAddress,
    required String stopAddresses,
    required String destinationAddress,
    required String destinationTextAddress,
    required String tripStartDate,
    required String tripEndDate,
    required String tripMiles,
    required String tripCaption,
    required String tripTag,
    required String tripSound,
    required List<Map<String, double>> tripCoordinates,
    required List<Map<String, double>> stopLocations,
    required List<Map<String, dynamic>> droppins,
    required String startLocation,
    required String destinationLocation,
    required String mapstyle,
    required String delayTime,
  }) async {
    final url = Uri.parse('$baseUrl/trip/create');

    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      'start_address': startAddress,
      'stop_address': stopAddresses,
      'destination_address': destinationAddress,
      'destination_text_address': destinationTextAddress,
      'trip_start_date': tripStartDate,
      'trip_end_date': tripEndDate,
      'trip_miles': tripMiles,
      'trip_caption': tripCaption,
      'trip_sound': tripSound,
      'trip_tags': tripTag,
      'trip_coordinates': tripCoordinates,
      'stop_locations': stopLocations,
      'droppins': droppins,
      'start_location': startLocation,
      'destination_location': destinationLocation,
      'map_style' : mapstyle,
      'delay_time' : delayTime
    };
    logger.i(requestBody);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'trip': responseData['trip']};
      } else {
        final responseData = jsonDecode(response.body);
        String error = responseData['error'] ?? 'An unknown error occurred.';
        logger.i("Failed to create trip: ${response.statusCode} - $error");
        return {'success': false, 'error': error};
      }
    } catch (e) {
      logger.i("Error creating trip: $e");
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateTrip({
    required int tripId,
    required int userId,
    required String startAddress,
    required String stopAddresses,
    required String destinationAddress,
    required String destinationTextAddress,
    required String tripStartDate,
    required String tripEndDate,
    required String tripMiles,
    required String tripTag,
    required String tripSound,
    required String tripCaption,
    required List<Map<String, double>> tripCoordinates,
    required List<Map<String, double>> stopLocations,
    required List<Map<String, dynamic>> droppins,
    required String startLocation,
    required String destinationLocation,
    required String mapStyle,
  }) async {
    final url = Uri.parse('$baseUrl/trip/update');
    final Map<String, dynamic> requestBody = {
      "id": tripId,
      'user_id': userId,
      'start_address': startAddress,
      'stop_address': stopAddresses,
      'destination_address': destinationAddress,
      'destination_text_address': destinationTextAddress,
      'trip_start_date': tripStartDate,
      'trip_end_date': tripEndDate,
      'trip_miles': tripMiles,
      'trip_sound': tripSound,
      'trip_tags': tripTag,
      'trip_caption': tripCaption,
      'trip_coordinates': tripCoordinates,
      'stop_locations': stopLocations,
      'droppins': droppins,
      'start_location': startLocation,
      'destination_location': destinationLocation,
      'map_style': mapStyle,
    };
    logger.i(requestBody);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'trip': responseData['trip']};
      } else {
        final responseData = jsonDecode(response.body);
        String error = responseData['error'] ?? 'An unknown error occurred.';
        logger.i("Failed: $responseData");
        logger.i("Failed to updateTrip trip: ${response.statusCode} - R$error");
        return {'success': false, 'error': error};
      }
    } catch (e) {
      logger.i("Error creating trip: $e");
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchUserTrips(int userId) async {
    final url = Uri.parse('$baseUrl/trip/trips/user?user_id=$userId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'trips': List<Map<String, dynamic>>.from(data['trips'] ?? []),
          'userInfo': List<Map<String, dynamic>>.from(data['userInfo'] ?? []),
        };
      } else {
        throw Exception('Failed to fetch user trips: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error in fetchUserTrips: $e');
      throw Exception('Failed to fetch user trips: $e');
    }
  }

  Future<Map<String, dynamic>?> sendComment({
    required int userId,
    required int tripId,
    required String content,
  }) async {
    final url = Uri.parse('$baseUrl/comment/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'trip_id': tripId,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      logger.e('Failed to send comment: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleDroppinLike({
    required int userId,
    required int droppinId,
    required bool flag,
  }) async {
    final url = Uri.parse('$baseUrl/user/droppin_like');
    // final url = Uri.parse('http://192.168.141.105:8000/api/user/droppin_like');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'droppin_id': droppinId,
        'flag': flag,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      logger.e('Failed to toggle like: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserInfo(int userId) async {
    final url = Uri.parse('$baseUrl/user/info?id=$userId');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == true) {
          return data['data'];
        } else {
          logger.e('Failed to fetch user info: ${data['message']}');
          return null;
        }
      } else {
        logger.e('Failed to fetch user info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error fetching user info: $e');
      return null;
    }
  }
}
