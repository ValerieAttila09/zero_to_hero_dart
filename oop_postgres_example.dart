import 'dart:io';
import 'dart:math';
import 'package:postgres/postgres.dart';

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

  factory User.fromPostgres(List<dynamic> row) {
    return User(
      id: row[0] as String,
      nama: row[1] as String,
      umur: row[2] as int,
      email: row[3] as String,
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

class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });
}

class UserRepository {
  final DatabaseConfig config;
  late Connection _connection;
  bool _isConnected = false;

  UserRepository(this.config);

  Future<void> connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: config.host,
          port: config.port,
          database: config.database,
          username: config.username,
          password: config.password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      _isConnected = true;
      print("✓ Berhasil terhubung ke database PostgreSQL\n");
      await _createTableIfNotExists();
    } catch (e) {
      print("✗ Error koneksi database: $e\n");
      _isConnected = false;
    }
  }

  Future<void> _createTableIfNotExists() async {
    try {
      await _connection.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id VARCHAR(16) PRIMARY KEY,
          nama VARCHAR(100) NOT NULL,
          umur INTEGER NOT NULL,
          email VARCHAR(100) NOT NULL UNIQUE
        )
      ''');
      print("✓ Tabel users sudah siap\n");
    } catch (e) {
      print("✗ Error membuat tabel: $e\n");
    }
  }

  Future<List<User>> loadUsers() async {
    if (!_isConnected) {
      print("Database tidak terhubung!");
      return [];
    }

    try {
      final result = await _connection.execute(
        'SELECT id, nama, umur, email FROM users ORDER BY nama',
      );

      List<User> users = [];
      for (final row in result) {
        users.add(User.fromPostgres(row.toColumnMap().values.toList()));
      }

      print("✓ Berhasil memuat ${users.length} user dari database\n");
      return users;
    } catch (e) {
      print("✗ Error memuat data: $e\n");
      return [];
    }
  }

  Future<bool> addUser(User user) async {
    if (!_isConnected) {
      print("Database tidak terhubung!");
      return false;
    }

    try {
      await _connection.execute(
        'INSERT INTO users (id, nama, umur, email) VALUES (\$1, \$2, \$3, \$4)',
        parameters: [user.id, user.nama, user.umur, user.email],
      );
      return true;
    } catch (e) {
      print("✗ Error menambah user: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    if (!_isConnected) {
      print("Database tidak terhubung!");
      return false;
    }

    try {
      final result = await _connection.execute(
        'DELETE FROM users WHERE id = \$1',
        parameters: [id],
      );
      return result.affectedRows > 0;
    } catch (e) {
      print("✗ Error menghapus user: $e");
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    if (!_isConnected) {
      print("Database tidak terhubung!");
      return false;
    }

    try {
      final result = await _connection.execute(
        'UPDATE users SET nama = \$1, umur = \$2, email = \$3 WHERE id = \$4',
        parameters: [user.nama, user.umur, user.email, user.id],
      );
      return result.affectedRows > 0;
    } catch (e) {
      print("✗ Error mengupdate user: $e");
      return false;
    }
  }

  Future<User?> findUserById(String id) async {
    if (!_isConnected) {
      print("Database tidak terhubung!");
      return null;
    }

    try {
      final result = await _connection.execute(
        'SELECT id, nama, umur, email FROM users WHERE id = \$1',
        parameters: [id],
      );

      if (result.isEmpty) {
        return null;
      }

      return User.fromPostgres(result.first.toColumnMap().values.toList());
    } catch (e) {
      print("✗ Error mencari user: $e");
      return null;
    }
  }

  Future<void> close() async {
    if (_isConnected) {
      await _connection.close();
      print("\n✓ Koneksi database ditutup");
    }
  }
}

class UserService {
  final UserRepository _repository;

  UserService(this._repository);

  Future<void> addUser(User user) async {
    bool success = await _repository.addUser(user);
    if (success) {
      print("Data berhasil ditambahkan!\n");
    }
  }

  Future<void> displayUsers() async {
    List<User> users = await _repository.loadUsers();
    
    if (users.isEmpty) {
      print("Tidak ada data user.\n");
      return;
    }
    
    for (var i = 0; i < users.length; i++) {
      print("\nData user ke-${i + 1} :");
      print(users[i]);
      print("");
    }
  }

  Future<bool> deleteUser(String id) async {
    bool success = await _repository.deleteUser(id);
    if (success) {
      print("Data berhasil dihapus!\n");
    } else {
      print("ID tidak ditemukan atau gagal menghapus!\n");
    }
    return success;
  }

  Future<bool> updateUser(String id, String nama, int umur, String email) async {
    User updatedUser = User(id: id, nama: nama, umur: umur, email: email);
    bool success = await _repository.updateUser(updatedUser);
    if (success) {
      print("Data berhasil diubah!\n");
    } else {
      print("ID tidak ditemukan atau gagal mengupdate!\n");
    }
    return success;
  }

  Future<User?> findUserById(String id) async {
    return await _repository.findUserById(id);
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

  Future<void> handleAddUser() async {
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

    await _userService.addUser(newUser);
    await _userService.displayUsers();
  }

  Future<void> handleViewUsers() async {
    print("\nLihat data");
    await _userService.displayUsers();
  }

  Future<void> handleDeleteUser() async {
    print("\nHapus data");
    stdout.write("Masukkan ID yang ingin dihapus : ");
    String id = stdin.readLineSync()!;
    await _userService.deleteUser(id);
  }

  Future<void> handleUpdateUser() async {
    print("\nUbah data");
    stdout.write("Masukkan ID yang ingin diubah : ");
    String id = stdin.readLineSync()!;

    User? existingUser = await _userService.findUserById(id);
    if (existingUser == null) {
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

    await _userService.updateUser(id, nama, umur, email);
    await _userService.displayUsers();
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

  UserManagementApp(DatabaseConfig config) {
    _repository = UserRepository(config);
    _userService = UserService(_repository);
    _ui = UserInterface(_userService);
  }

  Future<void> run() async {
    await _repository.connect();
    
    bool running = true;

    while (running) {
      _ui.showMenu();
      int choice = _ui.getMenuChoice();

      switch (choice) {
        case 1:
          await _ui.handleAddUser();
          break;
        case 2:
          await _ui.handleViewUsers();
          break;
        case 3:
          await _ui.handleDeleteUser();
          break;
        case 4:
          await _ui.handleUpdateUser();
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

    await _repository.close();
  }
}

void main() async {
  // Konfigurasi database PostgreSQL
  // Sesuaikan dengan kredensial database Anda
  DatabaseConfig config = DatabaseConfig(
    host: 'localhost',        // Ganti dengan host database Anda
    port: 5432,              // Port default PostgreSQL
    database: 'dart_db',     // Nama database Anda
    username: 'postgres',    // Username PostgreSQL
    password: 'password',    // Password PostgreSQL
  );

  UserManagementApp app = UserManagementApp(config);
  await app.run();
}
