import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final bool isTrainer;
  final String?  trainerId;
  final String? trainerName;
  final String? trainerCode;
  final String? trainerCodeUpdatedAt; 
  final List<String> traineeIds;
  final List<Map<String, dynamic>> trainees;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isTrainer,
    this.trainerId,
    this.trainerName,
    this.trainerCode,
    this.trainerCodeUpdatedAt,
    this.traineeIds = const [],
    this.trainees = const [],
  });

  bool get hasTrainer => trainerId != null && trainerId! .isNotEmpty;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // ✅ BULLETPROOF: Handle isTrainer field safely
    bool isTrainerValue = false;
    
    if (json['isTrainer'] != null) {
      if (json['isTrainer'] is bool) {
        isTrainerValue = json['isTrainer'];
      } else if (json['isTrainer'] is String) {
        isTrainerValue = json['isTrainer']. toString().toLowerCase() == 'true';
      }
    }

    // ✅ BULLETPROOF: Handle trainees array safely
    List<Map<String, dynamic>> traineesList = [];
    if (json['trainees'] != null && json['trainees'] is List) {
      traineesList = (json['trainees'] as List).map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    }

    return AppUser(
      id:  json['id']?. toString() ?? '',
      email:  json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isTrainer: isTrainerValue,
      trainerId: json['trainerId']?.toString(),
      trainerName: json['trainerName']?.toString(),
      trainerCode: json['trainerCode']?.toString(),
      trainerCodeUpdatedAt: json['trainerCodeUpdatedAt']?.toString(),
      traineeIds: json['traineeIds'] != null 
          ? List<String>.from(json['traineeIds']) 
          : [],
      trainees: traineesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isTrainer': isTrainer,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'trainerCode': trainerCode,
      'trainerCodeUpdatedAt':  trainerCodeUpdatedAt,
      'traineeIds': traineeIds,
      'trainees': trainees,
    };
  }
}