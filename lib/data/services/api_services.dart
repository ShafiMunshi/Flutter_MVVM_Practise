import 'package:http/http.dart' as http;

class ApiServices {
  final String baseUrl = "https://jsonplaceholder.typicode.com";
  final http.Client client;

  ApiServices({http.Client? client}) : client = client ?? http.Client();

  Future<http.Response> get(String endPoint) async {
    return await client.get(Uri.parse(baseUrl + endPoint));
  }
}
