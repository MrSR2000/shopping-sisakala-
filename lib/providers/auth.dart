import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? _authTimer;

  bool get isAuth {
    //print('${token != null}');
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token.toString();
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyDwUMEUbkebHfn57YuVZ5BfGBgmegSHY0E'),
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }

      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(responseData['expiresIn']),
        ),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final authData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String(),
        },
      );
      prefs.setString('userData', authData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
    // final response = await http.post(
    //   Uri.parse(
    //       'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyDwUMEUbkebHfn57YuVZ5BfGBgmegSHY0E'),
    //   body: json.encode(
    //     {
    //       'email': email,
    //       'password': password,
    //       'returnSecureToken': true,
    //     },
    //   ),
    // );
    // print(json.decode(response.body));
  }

  Future<void> signin(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');

    // final response = await http.post(
    //   Uri.parse(
    //       'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyDwUMEUbkebHfn57YuVZ5BfGBgmegSHY0E'),
    //   body: json.encode(
    //     {
    //       'email': email,
    //       'password': password,
    //       'returnSecureToken': true,
    //     },
    //   ),
    // );
    // final loginData = json.decode(response.body);
    // print(loginData);
  }

  // Future<bool> tryAutoLogin() async {
  //   print('i reached try auto login');
  //   final prefs = await SharedPreferences.getInstance();
  //   if (!(prefs.containsKey('authData'))) {
  //     return false;
  //   }
  //   final extractedUserAuth = json
  //       .decode(prefs.getString('authData').toString()) as Map<String, Object>;
  //   print('extracted data:  $extractedUserAuth');
  //   final expiryDate =
  //       DateTime.parse(extractedUserAuth['expiryDate'] as String);
  //   print(expiryDate);
  //   if (expiryDate.isBefore(DateTime.now())) {
  //     return false;
  //   }
  //   _token = extractedUserAuth['token'].toString();
  //   _userId = extractedUserAuth['userId'].toString();
  //   _expiryDate = expiryDate;
  //   notifyListeners();
  //   _autoLogout();
  //   return true;
  // }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      print('no key found');
      return false;
    }
    final extractedUserData =
        json.decode((prefs.getString('userData')).toString())
            as Map<String, dynamic>;
    final expiryDate =
        DateTime.parse(extractedUserData['expiryDate'].toString());

    if (expiryDate.isBefore(DateTime.now())) {
      print('expired');
      return false;
    }
    _token = extractedUserData['token'].toString();
    _userId = extractedUserData['userId'].toString();
    _expiryDate = expiryDate;
    print('lock and load ');
    _autoLogout();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    _token = null;
    _expiryDate = null;
    _userId = null;
    notifyListeners();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpire = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpire), logout);
    //print(timeToExpire);
  }
}
