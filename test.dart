import 'dart:io';
import 'dart:math';
import 'dart:convert';

String generate_id() {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(
    16,
    (index) => chars[Random().nextInt(chars.length)],
  ).join();
}

bool is_valid_email(String email) {
  final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
  return regex.hasMatch(email);
}

void main() {
  List<Map<String, dynamic>> users = [];
  final file = File('users.json');

  if (file.existsSync()) {
    try {
      String jsonString = file.readAsStringSync();
      List<dynamic> jsonData = jsonDecode(jsonString);
      users = jsonData.cast<Map<String, dynamic>>();
      print("Data existing berhasil dimuat dari users.json\n");
    } catch (e) {
      print("Error membaca file JSON: $e\n");
    }
  }

  while (true) {
    stdout.write("Masukkan nama : ");
    String? inp_nama = stdin.readLineSync()!;
    stdout.write("Masukkan umur : ");
    int? inp_umur = int.parse(stdin.readLineSync()!);
    stdout.write("Masukkan email : ");
    String? inp_email = stdin.readLineSync()!;

    if (!is_valid_email(inp_email)) {
      print("Email tidak valid!");
      break;
    } else {
      users.add({
        "id": generate_id(),
        "nama": inp_nama.toString(),
        "umur": inp_umur,
        "email": inp_email.toString(),
      });
    }
    for (var user in users) {
      print(
        "\nData user ke-${users.indexOf(user) + 1} :\n" +
        "ID : ${user["id"]}\nNama : ${user["nama"]}|nEmail : ${user["email"]}\nUmur : ${user["umur"]}\n\n",
      );
    }

    stdout.write("\nTambah data lagi? (y/n) : ");
    String? inp_lagi = stdin.readLineSync()!;
    if (inp_lagi == "n") {
      break;
    } else {
      continue;
    }
  }

  try {
    String jsonString = JsonEncoder.withIndent('  ').convert(users);
    file.writeAsStringSync(jsonString);
    print("\n✓ Data berhasil disimpan ke users.json");
    print("Total ${users.length} user tersimpan.");
  } catch (e) {
    print("\n✗ Error menyimpan file JSON: $e");
  }
}
