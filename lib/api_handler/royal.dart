import 'dart:convert';
import 'package:http/http.dart' as http;

class CurfoxService {
  Future<String?> getCurrentStatus(String waybill) async {
    final response = await http.post(
      Uri.parse("https://v1.api.curfox.com/api/public/order/tracking-info"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-tenant": "royalexpress",
        "Authorization":
            "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYjFiNDk3OWM1YjEyNjEwNjUxMGFhZDMyMDQ0MzBiMWE0NWYyZTFiMzAzOTIzMTQ3ZjdjM2YyNWEzMGZkMDU0MzdhZWZjNmJiOTVkZWI2OTEiLCJpYXQiOjE3NzI3MzU4MzMuMjM2NDYzLCJuYmYiOjE3NzI3MzU4MzMuMjM2NDY1LCJleHAiOjQ5Mjg0MDk0MzMuMjIyMzE0LCJzdWIiOiI0Njc0Iiwic2NvcGVzIjpbXX0.jVbxQXE8AOGvYuWPQmDGA7VyYvPyw73AnyiCpGgdd0XD7GQCtMj5HLn0YNADASZwWOxRxK9J92OB0CW3KD_ZUtku7VYIbb8SYKOYDzBNrdt8EfiM7cKMf8vWaD22jnwi33_TEEdWzQxuI5HMqkq0AiKOm93lKgt94SGmeSl_xlWORKBENB4qvawCiQhRgluMnyxInC7mmbPGgHY1Mx_4IZ5nEXto3C6wrlLdfPJNTlWnJPALeHKiNPRLD6kHS0-Mo_wotlddLRuKSfj19kxkazfBm-cuH8cJj76pFCuVKbQCWzC-ok7gK2-ZwO3nvEq9VnEQrG62bxkgFe8orEZIfm3Saw99sbUr7EwoHOvMircz4FMHm-ls5c8VqUpy81xn8TyYeZ6mTyZk0oJ0mVso_JbN5wU6hmKmxX-amhA2UTQ1f20Ic61JVskkmZjkmDmdBQBU2yribDqzD06_SH3I7n8KueHYNXOElHo-D1Gp2wU05zTdROMurfegGzTvCeR8v6lAaDygLXyG2quK6RF0LN_kwXat6JqRCAuyedHfzts0TEe1Yps8LY1LfyW4PtcFaZcUoLPjQwsDcM6yE0237I1qDMNhobp_qB_3V1xkenN7sPkLn47iRodN7-PoFMzG3xzffZvm4tVJBRcKuvxgTSCDf2GkJZSbz20RRv7kDZo",
      },
      body: jsonEncode({"waybill_number": waybill}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      var timeline = data["data"]["timeline"];

      return timeline[0]["status"]["name"];
    }

    return null;
  }
}
