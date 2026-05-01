import 'dart:io';

void main() async {
  final envFile = File('../../.env');
  if (envFile.existsSync()) {
    print("Found .env");
    print(await envFile.readAsString());
  } else {
    print(".env not found");
  }
}
