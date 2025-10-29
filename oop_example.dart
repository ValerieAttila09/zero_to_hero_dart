import 'dart:io';
import 'dart:math';
import 'dart:convert';

class User {
  String id;
  String nama;
  int umur;
  String email;

  User({
    required this.id,
    required this.nama,
    required this.umur,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nama: json['nama'] as String,
      umur: json['umur'] as int,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'umur': umur,
      'email': email,
    };
  }

  @override
  String toString() {
    return 'ID : $id\nNama : $nama\nEmail : $email\nUmur : $umur';
  }
}

class Utility {
  static String generateId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      16,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return regex.hasMatch(email);
  }
}

class UserRepository {
  final String filePath;

  UserRepository(this.filePath);

  List<User> loadUsers() {
    final file = File(filePath);
    if (file.existsSync()) {
      try {
        String jsonString = file.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        List<User> users = jsonData.map((json) => User.fromJson(json)).toList();
        print("Data existing berhasil dimuat dari $filePath\n");
        return users;
      } catch (e) {
        print("Error membaca file JSON: $e\n");
        return [];
      }
    }
    return [];
  }

  void saveUsers(List<User> users) {
    try {
      final file = File(filePath);
      List<Map<String, dynamic>> jsonData = users.map((user) => user.toJson()).toList();
      String jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
      file.writeAsStringSync(jsonString);
      print("\n✓ Data berhasil disimpan ke $filePath");
      print("Total ${users.length} user tersimpan.");
    } catch (e) {
      print("\n✗ Error menyimpan file JSON: $e");
    }
  }
}

class UserService {
  final List<User> _users;

  UserService(this._users);

  void addUser(User user) {
    _users.add(user);
    print("Data berhasil ditambahkan!\n");
  }

  void displayUsers() {
    if (_users.isEmpty) {
      print("Tidak ada data user.\n");
      return;
    }
    for (var i = 0; i < _users.length; i++) {
      print("\nData user ke-${i + 1} :");
      print(_users[i]);
      print("");
    }
  }

  bool deleteUser(String id) {
    int index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      print("ID tidak ditemukan!");
      return false;
    }
    _users.removeAt(index);
    print("Data berhasil dihapus!\n");
    return true;
  }

  bool updateUser(String id, String nama, int umur, String email) {
    int index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      print("ID tidak ditemukan!");
      return false;
    }
    _users[index].nama = nama;
    _users[index].umur = umur;
    _users[index].email = email;
    print("Data berhasil diubah!\n");
    return true;
  }

  User? findUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}

class UserInterface {
  final UserService _userService;

  UserInterface(this._userService);

  void showMenu() {
    print("Pilih menu :");
    print("1. Tambah data");
    print("2. Lihat data");
    print("3. Hapus data");
    print("4. Ubah data");
    print("5. Keluar");
  }

  void handleAddUser() {
    print("\nTambah data");
    print("Masukkan data yang diinginkan :");
    
    stdout.write("Masukkan nama : ");
    String nama = stdin.readLineSync()!;
    
    stdout.write("Masukkan umur : ");
    int umur = int.parse(stdin.readLineSync()!);
    
    stdout.write("Masukkan email : ");
    String email = stdin.readLineSync()!;

    if (!Utility.isValidEmail(email)) {
      print("Email tidak valid!");
      return;
    }

    User newUser = User(
      id: Utility.generateId(),
      nama: nama,
      umur: umur,
      email: email,
    );

    _userService.addUser(newUser);
    _userService.displayUsers();
  }

  void handleViewUsers() {
    print("\nLihat data");
    _userService.displayUsers();
  }

  void handleDeleteUser() {
    print("\nHapus data");
    stdout.write("Masukkan ID yang ingin dihapus : ");
    String id = stdin.readLineSync()!;
    _userService.deleteUser(id);
  }

  void handleUpdateUser() {
    print("\nUbah data");
    stdout.write("Masukkan ID yang ingin diubah : ");
    String id = stdin.readLineSync()!;

    if (_userService.findUserById(id) == null) {
      print("ID tidak ditemukan!");
      return;
    }

    stdout.write("Masukkan nama baru : ");
    String nama = stdin.readLineSync()!;
    
    stdout.write("Masukkan umur baru : ");
    int umur = int.parse(stdin.readLineSync()!);
    
    stdout.write("Masukkan email baru : ");
    String email = stdin.readLineSync()!;

    if (!Utility.isValidEmail(email)) {
      print("Email tidak valid!");
      return;
    }

    _userService.updateUser(id, nama, umur, email);
    _userService.displayUsers();
  }

  int getMenuChoice() {
    stdout.write("Masukkan pilihan : ");
    return int.parse(stdin.readLineSync()!);
  }

  bool askContinue() {
    stdout.write("\nMulai operasi lagi? (y/n) : ");
    String input = stdin.readLineSync()!;
    return input.toLowerCase() != 'n';
  }
}

class UserManagementApp {
  late UserRepository _repository;
  late UserService _userService;
  late UserInterface _ui;

  UserManagementApp(String filePath) {
    _repository = UserRepository(filePath);
    List<User> users = _repository.loadUsers();
    _userService = UserService(users);
    _ui = UserInterface(_userService);
  }

  void run() {
    bool running = true;

    while (running) {
      _ui.showMenu();
      int choice = _ui.getMenuChoice();

      switch (choice) {
        case 1:
          _ui.handleAddUser();
          break;
        case 2:
          _ui.handleViewUsers();
          break;
        case 3:
          _ui.handleDeleteUser();
          break;
        case 4:
          _ui.handleUpdateUser();
          break;
        case 5:
          print("Hasil operasi :");
          running = false;
          continue;
        default:
          print("Pilihan tidak valid");
      }

      if (running && !_ui.askContinue()) {
        running = false;
      }
    }

    _repository.saveUsers(_userService._users);
  }
}

void main() {
  UserManagementApp app = UserManagementApp('users.json');
  app.run();
}
