import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'openid_io.dart' if (dart.library.html) 'openid_browser.dart';
import 'package:http/http.dart' as http;

const openiddictUrl = 'http://192.168.8.109:7211'; 
const scopes = [
    'openid',
    'profile',
    'email',
    // 'offline_access',
    'apibff'];

Credential? credential;

late final Client client;

Future<Client> getClient() async {
  var uri = Uri.parse(openiddictUrl);
  if (!kIsWeb && Platform.isAndroid) uri = uri.replace(host: '192.168.8.109');
  var clientId = 'FlutterClient';

  var issuer = await Issuer.discover(uri);
  return Client(issuer, clientId);
}

Future<void> main() async {
  client = await getClient();
  credential = await getRedirectResult(client, scopes: scopes);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'openid_client demo',
      home: MyHomePage(title: 'Openiddict + Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  UserInfo? userInfo;

  TokenResponse? tokenResponse=null;

  @override
  void initState() {
    if (credential != null) {
      credential!.getUserInfo().then((userInfo) {
        setState(() {
          this.userInfo = userInfo;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (userInfo != null) ...[
              Text('Hello ${userInfo!.email}'), 
              OutlinedButton(
                  child: const Text('Logout'),
                  onPressed: () async {
                    setState(() {
                      userInfo = null;
                    });
                  }),
                  OutlinedButton(
                  child: const Text('Weather'),
                  onPressed: () async {
                    var url = 'http://192.168.8.109:7105/WeatherForecast';
                    var access_token = tokenResponse?.accessToken;
                    if(access_token!=null) { 
                      var response = await http
                          .get(Uri.parse(url), headers: {"Authorization": "Bearer $access_token"});
                      var body = response.body;

                      // ignore: use_build_context_synchronously
                      showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Json"),
                          content: Text(body),
                          actions: [
                            TextButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                },
                            )
                          ],
                        );
                      },
                    );

                    }
                  })
            ],
            if (userInfo == null)
              OutlinedButton(
                  child: const Text('Login'),
                  onPressed: () async {
                    var credential = await authenticate(client, scopes: scopes);
                    tokenResponse=await credential.getTokenResponse(); 
                    var userInfo = await credential.getUserInfo();
                    setState(() {
                      this.userInfo = userInfo;
                    });
                  }),
          ],
        ),
      ),
    );
  }
}