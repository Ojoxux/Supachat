import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gdjbdbrfftsbhpwtpbfh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkamJkYnJmZnRzYmhwd3RwYmZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwMDk5NTgsImV4cCI6MjA2NDU4NTk1OH0.88BdD076_CcS2KvRmO3hfmDLkRxMhcSp4V2SoPYkeIo',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Supachat', home: const Scaffold());
  }
}
