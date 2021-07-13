import 'dart:convert';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class MeetingService extends Service {

  Future<List<Meeting>> getMeetings({team : String, company : String, event : int}) async {
      var queryParameters = {
        'team' : team,
        'company' : company,
        'event' : event
      };

      Response<String> response = 
          await dio.get("/meetings", queryParameters : queryParameters);

      if(response.statusCode == 200) {
          final responseJson = json.decode(response.data) as List;
          List<Meeting> meetings = 
              responseJson.map( (e) => Meeting.fromJson(e)).toList();
          return meetings;
      } else {
          // TODO : Handle Error
          print("error");
          return [];
      }
  }

   Future<Meeting> createMeeting(DateTime begin, DateTime end, String place, MeetingParticipants participants) async {
      var body = {
         "begin" : begin,
         "end" : end,
         "place" : place,
         "participants" : participants
      };

      Response<String> response = await dio.post("/meetings", data: body );

      if (response.statusCode == 200){
        return Meeting.fromJson(json.decode(response.data));
      } else {
        // TODO: Handle Error
        print("error");
        return null;
      }

   }

   Future<Meeting> getMeeting(String id) async {
      Response<String> response = await dio.get("/meetings/" + id);

      if ( response.statusCode == 200) {
        return Meeting.fromJson(json.decode(response.data));
      }
    }

   Future<Meeting> deleteMeeting(String id) async {
      Response<String> response = await dio.delete("/meetings/" + id);
      if (response.statusCode == 200) {
        return Meeting.fromJson(json.decode(response.data));
      } else {
        // TODO: Handle Error
        print("error");
        return null;
      }
   }

   Future<Meeting> updateMeeting(String id, DateTime begin, DateTime end, String place,
   //, MeetingParticipants participants
   ) async {
      var body = {
         "begin" : begin,
         "end" : end,
         "place" : place
         //, "participants" : participants
      };

    Response<String> response = await dio.put("/meetings/" + id, data: body);
    if (response.statusCode == 200) {
        return Meeting.fromJson(json.decode(response.data));
      } else {
        // TODO: Handle Error
        print("error");
        return null;
      }
   }

    Future<Meeting> uploadMeetingMinute(String id, String minute) async {
        // TODO: Implement : https://pub.dev/packages/dio
    }


}