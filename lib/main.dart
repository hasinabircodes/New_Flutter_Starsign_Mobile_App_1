
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ZodicApp());
}

class ZodicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zodic - Astrology App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Simple in-memory storage for demo
    await Future.delayed(Duration(milliseconds: 500));

    // Check if user data exists in memory
    if (AuthService().currentUser != null) {
      if (mounted) {
        setState(() {
          _userData = AuthService().currentUser;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ),
      );
    }

    return _userData == null ? WelcomeScreen() : AnimatedLoginPage(userData: _userData!);
  }
}

class UserData {
  final String name;
  final String email;
  final DateTime birthDate;
  final DateTime createdAt;

  UserData({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'birthDate': birthDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    name: json['name'],
    email: json['email'],
    birthDate: DateTime.parse(json['birthDate']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Simple in-memory storage for demo
  List<Map<String, dynamic>> _users = [];
  UserData? _currentUser;

  UserData? get currentUser => _currentUser;

  // Simple hash function for demo
  String _simpleHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.abs().toString();
  }

  // Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    // Validate email
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    // Check if email already exists
    for (final user in _users) {
      if (user['email'] == email) {
        throw Exception('Email already registered');
      }
    }

    // Create user data
    final userData = UserData(
      name: name,
      email: email,
      birthDate: birthDate,
      createdAt: DateTime.now(),
    );

    // Save user
    _users.add({
      'email': email,
      'password': _simpleHash(password),
      'data': userData.toJson(),
    });

    // Set as current user
    _currentUser = userData;

    return true;
  }

  // Login user
  Future<UserData> login({
    required String email,
    required String password,
  }) async {
    // Validate email
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    // Find user
    Map<String, dynamic>? user;
    for (final u in _users) {
      if (u['email'] == email) {
        user = u;
        break;
      }
    }

    if (user == null) {
      throw Exception('User not found');
    }

    // Check password
    if (user['password'] != _simpleHash(password)) {
      throw Exception('Invalid password');
    }

    final userData = UserData.fromJson(user['data']);

    // Set as current user
    _currentUser = userData;

    return userData;
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // Update user profile
  Future<void> updateProfile({
    required String name,
    required DateTime birthDate,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = UserData(
      name: name,
      email: _currentUser!.email,
      birthDate: birthDate,
      createdAt: _currentUser!.createdAt,
    );

    // Update in storage
    for (int i = 0; i < _users.length; i++) {
      if (_users[i]['email'] == _currentUser!.email) {
        _users[i]['data'] = updatedUser.toJson();
        break;
      }
    }

    // Update current user
    _currentUser = updatedUser;
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  List<Widget> _buildStars(BuildContext context) {
    final Random random = Random();
    return List.generate(60, (index) {
      final double top = random.nextDouble() * MediaQuery.of(context).size.height;
      final double left = random.nextDouble() * MediaQuery.of(context).size.width;
      final double size = random.nextDouble() * 3 + 1;
      final double opacity = random.nextDouble() * 0.6 + 0.2;

      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    colors: [
                      Colors.deepPurple.shade900,
                      Colors.purple.shade800,
                      Colors.pink.shade600,
                      Colors.deepPurple.shade900,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    transform: GradientRotation(_gradientController.value * 2 * pi),
                  ),
                ),
              );
            },
          ),

          // Stars
          ..._buildStars(context),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: 2),

                  // Logo and Title
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 100,
                            color: Colors.white,
                          ),
                          SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Colors.white, Colors.amber.shade200],
                            ).createShader(bounds),
                            child: Text(
                              "ZODIC",
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Discover Your Cosmic Journey",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Spacer(flex: 3),

                  // Auth Buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Guest Button
                        TextButton(
                          onPressed: () async {
                            await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnimatedLoginPage(userData: null),
                              ),
                            );
                          },
                          child: Text(
                            "Continue as Guest",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      "By continuing, you agree to our Terms & Privacy Policy",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Simple email validation
  bool _validateEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userData = await AuthService().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${userData.name}!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AnimatedLoginPage(userData: userData),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<Widget> _buildStars(BuildContext context) {
    final Random random = Random();
    return List.generate(40, (index) {
      final double top = random.nextDouble() * MediaQuery.of(context).size.height;
      final double left = random.nextDouble() * MediaQuery.of(context).size.width;
      final double size = random.nextDouble() * 3 + 1;
      final double opacity = random.nextDouble() * 0.6 + 0.2;

      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.purple.shade600,
                  Colors.pink.shade400,
                ],
              ),
            ),
          ),

          // Stars
          ..._buildStars(context),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Back Button
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Title
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Sign in to continue your cosmic journey",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      SizedBox(height: 40),

                      // Login Form
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!_validateEmail(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 24),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: _isLoading
                                      ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                  )
                                      : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Forgot Password
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Password reset feature coming soon!'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8),

                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Simple email validation
  bool _validateEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select your birth date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final success = await AuthService().register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          birthDate: _selectedDate!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AnimatedLoginPage(
                userData: UserData(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  birthDate: _selectedDate!,
                  createdAt: DateTime.now(),
                ),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<Widget> _buildStars(BuildContext context) {
    final Random random = Random();
    return List.generate(40, (index) {
      final double top = random.nextDouble() * MediaQuery.of(context).size.height;
      final double left = random.nextDouble() * MediaQuery.of(context).size.width;
      final double size = random.nextDouble() * 3 + 1;
      final double opacity = random.nextDouble() * 0.6 + 0.2;

      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.purple.shade600,
                  Colors.pink.shade400,
                ],
              ),
            ),
          ),

          // Stars
          ..._buildStars(context),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Back Button
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Title
                      Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Start your cosmic journey today",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      SizedBox(height: 30),

                      // Registration Form
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: "Full Name",
                                    prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    if (value.length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!_validateEmail(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Birth Date Field
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "Birth Date",
                                        prefixIcon: Icon(Icons.calendar_today, color: Colors.deepPurple),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        suffixIcon: Icon(Icons.arrow_drop_down),
                                      ),
                                      controller: TextEditingController(
                                        text: _selectedDate == null
                                            ? "Select your birth date"
                                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                      ),
                                      validator: (value) {
                                        if (_selectedDate == null) {
                                          return 'Please select your birth date';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Confirm Password Field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: "Confirm Password",
                                    prefixIcon: Icon(Icons.lock_outline, color: Colors.deepPurple),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 30),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: _isLoading
                                      ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                  )
                                      : ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Terms and Conditions
                                Text(
                                  "By creating an account, you agree to our Terms of Service and Privacy Policy",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 8),

                                // Sign In Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LoginPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Sign In",
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Update AnimatedLoginPage constructor to accept userData
class AnimatedLoginPage extends StatefulWidget {
  final UserData? userData;

  const AnimatedLoginPage({Key? key, required this.userData}) : super(key: key);

  @override
  _AnimatedLoginPageState createState() => _AnimatedLoginPageState();
}

class _AnimatedLoginPageState extends State<AnimatedLoginPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  DateTime? _selectedDate;

  double _opacity = 0.0;
  double _cardOffset = 50.0;
  late AnimationController _iconController;
  late AnimationController _shakeController;
  late AnimationController _gradientController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If user is logged in, pre-fill data
    if (widget.userData != null) {
      _nameController.text = widget.userData!.name;
      _selectedDate = widget.userData!.birthDate;
    }

    Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
        _cardOffset = 0.0;
      });
    });

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconController.dispose();
    _shakeController.dispose();
    _gradientController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);

      // Update user data if logged in
      if (widget.userData != null) {
        await AuthService().updateProfile(
          name: _nameController.text,
          birthDate: picked,
        );
      }
    }
  }

  void _login() async {
    if (_nameController.text.isEmpty || _selectedDate == null) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimatedHomePage(
            name: _nameController.text,
            birthDate: _selectedDate!,
            userData: widget.userData,
          ),
        ),
      );
    }
  }

  // Add logout function
  Future<void> _logout() async {
    await AuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(),
      ),
    );
  }

  List<Widget> _buildStars() {
    final Random random = Random();
    return List.generate(80, (index) {
      final double top = random.nextDouble() * MediaQuery.of(context).size.height;
      final double left = random.nextDouble() * MediaQuery.of(context).size.width;
      final double size = random.nextDouble() * 4 + 1;
      final double opacity = random.nextDouble() * 0.8 + 0.2;

      return Positioned(
        top: top,
        left: left,
        child: AnimatedContainer(
          duration: Duration(seconds: random.nextInt(3) + 2),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  List<Widget> _buildFloatingPlanets() {
    final List<Map<String, dynamic>> planets = [
      {'size': 40.0, 'color': Colors.orange, 'left': 0.1, 'top': 0.2, 'duration': 4000},
      {'size': 25.0, 'color': Colors.yellow, 'left': 0.8, 'top': 0.1, 'duration': 5000},
      {'size': 35.0, 'color': Colors.red, 'left': 0.15, 'top': 0.7, 'duration': 4500},
      {'size': 30.0, 'color': Colors.blue, 'left': 0.75, 'top': 0.8, 'duration': 5500},
    ];

    return planets.map((planet) {
      return Positioned(
        left: MediaQuery.of(context).size.width * planet['left'],
        top: MediaQuery.of(context).size.height * planet['top'],
        child: TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 2 * pi),
          duration: Duration(milliseconds: planet['duration']),
          curve: Curves.linear,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value,
              child: child,
            );
          },
          child: Container(
            width: planet['size'],
            height: planet['size'],
            decoration: BoxDecoration(
              color: planet['color'],
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  planet['color'],
                  planet['color'].withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: planet['color'].withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    colors: [
                      Colors.deepPurple.shade800,
                      Colors.purple.shade600,
                      Colors.pink.shade400,
                      Colors.deepPurple.shade800,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    transform: GradientRotation(_gradientController.value * 2 * pi),
                  ),
                ),
              );
            },
          ),

          // Stars
          ..._buildStars(),

          // Planets
          ..._buildFloatingPlanets(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    offset: Offset(0, _cardOffset),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              _shakeController.value * 10 * sin(_shakeController.value * 10),
                              0,
                            ),
                            child: child,
                          );
                        },
                        child: Card(
                          elevation: 20,
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // User info if logged in
                                if (widget.userData != null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Welcome back,",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            widget.userData!.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: Colors.deepPurple),
                                        onSelected: (value) {
                                          if (value == 'logout') {
                                            _logout();
                                          } else if (value == 'profile') {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Profile page coming soon!'),
                                                backgroundColor: Colors.blue,
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'profile',
                                            child: Row(
                                              children: [
                                                Icon(Icons.person, size: 20),
                                                SizedBox(width: 8),
                                                Text('Profile'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'logout',
                                            child: Row(
                                              children: [
                                                Icon(Icons.logout, size: 20),
                                                SizedBox(width: 8),
                                                Text('Logout'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Divider(),
                                  SizedBox(height: 20),
                                ],

                                // Icon Animation
                                ScaleTransition(
                                  scale: Tween(begin: 1.0, end: 1.1).animate(
                                    CurvedAnimation(
                                      parent: _iconController,
                                      curve: Curves.elasticOut,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    size: 80,
                                    color: Colors.deepPurple,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // App Title
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.deepPurple, Colors.pinkAccent],
                                  ).createShader(bounds),
                                  child: const Text(
                                    "Zodic Journey",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Discover Your Cosmic Blueprint",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 30),

                                // Name Input
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: widget.userData != null
                                        ? "Update your name"
                                        : "Enter your name",
                                    prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Birth Date Selection
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: _selectedDate == null
                                        ? Colors.grey.shade50
                                        : Colors.green.shade50,
                                  ),
                                  child: ListTile(
                                    onTap: _pickDate,
                                    leading: Icon(
                                      Icons.calendar_today,
                                      color: _selectedDate == null
                                          ? Colors.grey
                                          : Colors.green,
                                    ),
                                    title: Text(
                                      _selectedDate == null
                                          ? widget.userData != null
                                          ? "Update Birth Date"
                                          : "Select Birth Date"
                                          : "Birth Date Selected ✓",
                                      style: TextStyle(
                                        color: _selectedDate == null
                                            ? Colors.grey
                                            : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: _selectedDate != null
                                        ? Text(
                                      "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    )
                                        : null,
                                    trailing: const Icon(Icons.arrow_drop_down),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Continue Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: _isLoading
                                      ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                  )
                                      : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.deepPurple.withOpacity(0.5),
                                    ),
                                    onPressed: _login,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Explore Your Sign",
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Update AnimatedHomePage constructor
class AnimatedHomePage extends StatefulWidget {
  final String name;
  final DateTime birthDate;
  final UserData? userData;

  const AnimatedHomePage({
    required this.name,
    required this.birthDate,
    this.userData,
  });

  @override
  State<AnimatedHomePage> createState() => _AnimatedHomePageState();
}

class _AnimatedHomePageState extends State<AnimatedHomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _gradientController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _opacity = 0.0;

  int _selectedTab = 0;
  final List<DailyHoroscope> _weeklyHoroscope = [];
  final List<Meditation> _meditations = [];

  List<int> _luckyNumbers = [];
  List<String> _luckyColors = [];

  String _currentMoonPhase = "";
  String _moonPhaseEmoji = "";
  String _moonPhaseDescription = "";

  final List<String> _dailyAffirmations = [
    "I am aligned with the universe's positive energy",
    "My intuition guides me to make the right choices",
    "I attract abundance and opportunities today",
    "I am grateful for the cosmic guidance in my life",
    "My energy vibrates with positivity and light",
    "I trust the journey and embrace each moment",
    "The universe conspires in my favor today",
    "I am open to receiving cosmic blessings",
    "My path is illuminated with divine light",
    "I radiate positive energy that attracts goodness"
  ];
  String _currentAffirmation = "";

  String _partnerZodiac = "";
  String _compatibilityResult = "";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _initializeData();

    Timer(const Duration(milliseconds: 500), () {
      _controller.forward();
      setState(() => _opacity = 1.0);
    });
  }

  void _initializeData() {
    _weeklyHoroscope.addAll([
      DailyHoroscope(day: 'Monday', prediction: 'Great day for new beginnings', luckyNumber: 7),
      DailyHoroscope(day: 'Tuesday', prediction: 'Focus on communication', luckyNumber: 3),
      DailyHoroscope(day: 'Wednesday', prediction: 'Unexpected opportunities arise', luckyNumber: 9),
      DailyHoroscope(day: 'Thursday', prediction: 'Time for self-reflection', luckyNumber: 2),
      DailyHoroscope(day: 'Friday', prediction: 'Social connections bring joy', luckyNumber: 5),
      DailyHoroscope(day: 'Saturday', prediction: 'Creative energy peaks', luckyNumber: 8),
      DailyHoroscope(day: 'Sunday', prediction: 'Perfect for relaxation', luckyNumber: 1),
    ]);

    _meditations.addAll([
      Meditation(title: 'New Moon Meditation', duration: '15 min', type: 'Guided'),
      Meditation(title: 'Full Moon Release', duration: '20 min', type: 'Guided'),
      Meditation(title: 'Zodiac Alignment', duration: '10 min', type: 'Silent'),
      Meditation(title: 'Cosmic Energy Flow', duration: '25 min', type: 'Guided'),
    ]);

    _generateLuckyNumbersAndColors();
    _calculateMoonPhase();
    _generateDailyAffirmation();
  }

  void _generateDailyAffirmation() {
    final random = Random();
    setState(() {
      _currentAffirmation = _dailyAffirmations[random.nextInt(_dailyAffirmations.length)];
    });
  }

  void _checkQuickCompatibility(String userZodiac, String partnerZodiac) {
    Map<String, List<String>> compatibilityMap = {
      'Aries ♈': ['Leo ♌', 'Sagittarius ♐', 'Gemini ♊', 'Aquarius ♒'],
      'Taurus ♉': ['Virgo ♍', 'Capricorn ♑', 'Cancer ♋', 'Pisces ♓'],
      'Gemini ♊': ['Libra ♎', 'Aquarius ♒', 'Aries ♈', 'Leo ♌'],
      'Cancer ♋': ['Scorpio ♏', 'Pisces ♓', 'Taurus ♉', 'Virgo ♍'],
      'Leo ♌': ['Aries ♈', 'Sagittarius ♐', 'Gemini ♊', 'Libra ♎'],
      'Virgo ♍': ['Taurus ♉', 'Capricorn ♑', 'Cancer ♋', 'Scorpio ♏'],
      'Libra ♎': ['Gemini ♊', 'Aquarius ♒', 'Leo ♌', 'Sagittarius ♐'],
      'Scorpio ♏': ['Cancer ♋', 'Pisces ♓', 'Virgo ♍', 'Capricorn ♑'],
      'Sagittarius ♐': ['Aries ♈', 'Leo ♌', 'Libra ♎', 'Aquarius ♒'],
      'Capricorn ♑': ['Taurus ♉', 'Virgo ♍', 'Scorpio ♏', 'Pisces ♓'],
      'Aquarius ♒': ['Gemini ♊', 'Libra ♎', 'Aries ♈', 'Sagittarius ♐'],
      'Pisces ♓': ['Cancer ♋', 'Scorpio ♏', 'Taurus ♉', 'Capricorn ♑'],
    };

    if (userZodiac == partnerZodiac) {
      setState(() => _compatibilityResult = "⭐ Good match! Same signs understand each other deeply and share similar energies.");
    } else if (compatibilityMap[userZodiac]?.contains(partnerZodiac) ?? false) {
      setState(() => _compatibilityResult = "✨ Excellent cosmic connection! Your energies harmonize beautifully together.");
    } else {
      setState(() => _compatibilityResult = "💫 Interesting dynamic! This pairing offers great potential for growth and learning.");
    }
  }

  Widget _buildAffirmationCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Daily Affirmation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.amber),
                  onPressed: _generateDailyAffirmation,
                  tooltip: 'Get new affirmation',
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _currentAffirmation.isNotEmpty ? _currentAffirmation : "Tap refresh for your cosmic affirmation",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Repeat this affirmation throughout your day to align with positive cosmic energy!",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCompatibilityCard(String userZodiac) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink),
                SizedBox(width: 8),
                Text(
                  "Quick Compatibility Check",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _partnerZodiac.isEmpty ? null : _partnerZodiac,
                items: [
                  "Aries ♈", "Taurus ♉", "Gemini ♊", "Cancer ♋",
                  "Leo ♌", "Virgo ♍", "Libra ♎", "Scorpio ♏",
                  "Sagittarius ♐", "Capricorn ♑", "Aquarius ♒", "Pisces ♓"
                ].map((String sign) {
                  return DropdownMenuItem<String>(
                    value: sign,
                    child: Text(
                      sign,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _partnerZodiac = value);
                    _checkQuickCompatibility(userZodiac, value);
                  }
                },
                isExpanded: true,
                hint: Text("Select partner's zodiac sign"),
                underline: SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.pink),
              ),
            ),
            if (_compatibilityResult.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights, color: Colors.pink),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _compatibilityResult,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.pink.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 8),
            Text(
              "Discover how your energies interact with other zodiac signs",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _generateLuckyNumbersAndColors() {
    final Random random = Random();

    _luckyNumbers = [];
    while (_luckyNumbers.length < 3) {
      int number = random.nextInt(100) + 1;
      if (!_luckyNumbers.contains(number)) {
        _luckyNumbers.add(number);
      }
    }

    final List<String> allColors = [
      'Deep Purple', 'Royal Blue', 'Emerald Green', 'Sunset Orange',
      'Ruby Red', 'Gold', 'Silver', 'Turquoise', 'Magenta', 'Sapphire',
      'Amethyst Purple', 'Rose Pink', 'Ocean Blue', 'Forest Green'
    ];

    _luckyColors = [];
    while (_luckyColors.length < 3) {
      String color = allColors[random.nextInt(allColors.length)];
      if (!_luckyColors.contains(color)) {
        _luckyColors.add(color);
      }
    }
  }

  void _calculateMoonPhase() {
    final now = DateTime.now();

    final referenceNewMoon = DateTime(2024, 1, 11);
    final daysSinceNewMoon = now.difference(referenceNewMoon).inDays;
    final moonAge = daysSinceNewMoon % 29.53;

    if (moonAge < 1.0) {
      _currentMoonPhase = "New Moon";
      _moonPhaseEmoji = "🌑";
      _moonPhaseDescription = "New beginnings, fresh starts";
    } else if (moonAge < 7.4) {
      _currentMoonPhase = "Waxing Crescent";
      _moonPhaseEmoji = "🌒";
      _moonPhaseDescription = "Setting intentions, growth";
    } else if (moonAge < 8.4) {
      _currentMoonPhase = "First Quarter";
      _moonPhaseEmoji = "🌓";
      _moonPhaseDescription = "Taking action, decisions";
    } else if (moonAge < 14.8) {
      _currentMoonPhase = "Waxing Gibbous";
      _moonPhaseEmoji = "🌔";
      _moonPhaseDescription = "Refinement, adjustment";
    } else if (moonAge < 15.8) {
      _currentMoonPhase = "Full Moon";
      _moonPhaseEmoji = "🌕";
      _moonPhaseDescription = "Clarity, completion, release";
    } else if (moonAge < 22.2) {
      _currentMoonPhase = "Waning Gibbous";
      _moonPhaseEmoji = "🌖";
      _moonPhaseDescription = "Gratitude, sharing wisdom";
    } else if (moonAge < 23.2) {
      _currentMoonPhase = "Last Quarter";
      _moonPhaseEmoji = "🌗";
      _moonPhaseDescription = "Letting go, forgiveness";
    } else {
      _currentMoonPhase = "Waning Crescent";
      _moonPhaseEmoji = "🌘";
      _moonPhaseDescription = "Rest, reflection, surrender";
    }
  }

  void _refreshLuckyNumbers() {
    setState(() {
      _generateLuckyNumbersAndColors();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ New lucky numbers & colors generated!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  String getZodiacSign(DateTime date) {
    final int day = date.day;
    final int month = date.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries ♈";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus ♉";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini ♊";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer ♋";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo ♌";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo ♍";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra ♎";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio ♏";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius ♐";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn ♑";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius ♒";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Pisces ♓";
    return "Unknown";
  }

  Map<String, dynamic> calculateNumerology(String name, DateTime birthDate) {
    int soulUrgeNumber = _calculateSoulUrgeNumber(name);
    int birthdayNumber = _calculateBirthdayNumber(birthDate);
    int lifePathNumber = _calculateLifePathNumber(birthDate);
    int destinyNumber = _calculateDestinyNumber(name);

    return {
      'soul_urge': soulUrgeNumber,
      'soul_urge_meaning': _getSoulUrgeMeaning(soulUrgeNumber),
      'birthday': birthdayNumber,
      'birthday_meaning': _getBirthdayMeaning(birthdayNumber),
      'life_path': lifePathNumber,
      'life_path_meaning': _getLifePathMeaning(lifePathNumber),
      'destiny': destinyNumber,
      'destiny_meaning': _getDestinyMeaning(destinyNumber),
    };
  }

  int _calculateSoulUrgeNumber(String name) {
    String cleanName = name.replaceAll(' ', '').toUpperCase();
    String vowels = 'AEIOU';
    int sum = 0;

    for (int i = 0; i < cleanName.length; i++) {
      String char = cleanName[i];
      if (vowels.contains(char)) {
        switch (char) {
          case 'A': sum += 1; break;
          case 'E': sum += 5; break;
          case 'I': sum += 9; break;
          case 'O': sum += 6; break;
          case 'U': sum += 3; break;
        }
      }
    }

    return _reduceToSingleDigit(sum);
  }

  int _calculateBirthdayNumber(DateTime birthDate) {
    return _reduceToSingleDigit(birthDate.day);
  }

  int _calculateLifePathNumber(DateTime birthDate) {
    int daySum = _reduceToSingleDigit(birthDate.day);
    int monthSum = _reduceToSingleDigit(birthDate.month);
    int yearSum = _reduceToSingleDigit(_reduceToSingleDigit(birthDate.year));

    int total = daySum + monthSum + yearSum;
    return _reduceToSingleDigit(total);
  }

  int _calculateDestinyNumber(String name) {
    String cleanName = name.replaceAll(' ', '').toUpperCase();
    int sum = 0;

    for (int i = 0; i < cleanName.length; i++) {
      String char = cleanName[i];
      int position = char.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
      int value = ((position - 1) % 9) + 1;
      sum += value;
    }

    return _reduceToSingleDigit(sum);
  }

  int _reduceToSingleDigit(int number) {
    while (number > 9 && number != 11 && number != 22 && number != 33) {
      int sum = 0;
      String numberStr = number.toString();
      for (int i = 0; i < numberStr.length; i++) {
        sum += int.parse(numberStr[i]);
      }
      number = sum;
    }
    return number;
  }

  String _getSoulUrgeMeaning(int number) {
    switch (number) {
      case 1: return 'You desire independence, leadership, and new beginnings. You seek to express your individuality and take initiative.';
      case 2: return 'You crave harmony, partnership, and peace. You desire emotional security and meaningful connections with others.';
      case 3: return 'You seek creative expression, joy, and social interaction. You desire to share your talents and inspire others.';
      case 4: return 'You value stability, security, and practical achievements. You desire to build solid foundations and be reliable.';
      case 5: return 'You crave freedom, adventure, and variety. You desire change, excitement, and new experiences.';
      case 6: return 'You seek harmony, responsibility, and nurturing relationships. You desire to care for others and create beauty.';
      case 7: return 'You desire knowledge, wisdom, and spiritual understanding. You seek truth and inner development.';
      case 8: return 'You crave success, abundance, and material achievement. You desire power, recognition, and financial security.';
      case 9: return 'You seek humanitarian service, compassion, and universal love. You desire to make the world a better place.';
      case 11: return 'You desire spiritual enlightenment, inspiration, and higher consciousness. You seek to uplift humanity.';
      case 22: return 'You crave to manifest grand visions and make a significant impact on the world through practical means.';
      case 33: return 'You desire to serve humanity through compassion, healing, and spiritual guidance on a grand scale.';
      default: return 'Unknown soul urge number meaning.';
    }
  }

  String _getBirthdayMeaning(int number) {
    switch (number) {
      case 1: return 'Natural leader, independent, ambitious, and innovative. You shine when taking initiative.';
      case 2: return 'Cooperative, diplomatic, sensitive, and intuitive. You excel in partnerships and teamwork.';
      case 3: return 'Creative, expressive, optimistic, and social. You bring joy and inspiration to others.';
      case 4: return 'Practical, organized, reliable, and hardworking. You build solid foundations.';
      case 5: return 'Adventurous, freedom-loving, adaptable, and progressive. You embrace change and variety.';
      case 6: return 'Nurturing, responsible, compassionate, and harmonious. You create beauty and care for others.';
      case 7: return 'Analytical, spiritual, introspective, and wise. You seek truth and deeper understanding.';
      case 8: return 'Ambitious, authoritative, successful, and financially savvy. You achieve material mastery.';
      case 9: return 'Humanitarian, compassionate, artistic, and wise. You serve others selflessly.';
      default: return 'Unknown birthday number meaning.';
    }
  }

  String _getLifePathMeaning(int number) {
    switch (number) {
      case 1: return 'The Leader - Your life path is about independence, innovation, and pioneering new directions.';
      case 2: return 'The Peacemaker - Your path focuses on cooperation, diplomacy, and creating harmony.';
      case 3: return 'The Creative - Your journey involves self-expression, joy, and inspiring others.';
      case 4: return 'The Builder - Your path is about creating stability, security, and practical foundations.';
      case 5: return 'The Adventurer - Your journey embraces freedom, change, and diverse experiences.';
      case 6: return 'The Nurturer - Your path focuses on responsibility, family, and creating beauty.';
      case 7: return 'The Seeker - Your journey involves spiritual wisdom, analysis, and inner development.';
      case 8: return 'The Achiever - Your path is about material success, authority, and abundance.';
      case 9: return 'The Humanitarian - Your journey involves compassion, service, and universal love.';
      case 11: return 'The Intuitive - Your path is about spiritual enlightenment and inspired teaching.';
      case 22: return 'The Master Builder - Your journey involves turning grand visions into reality.';
      case 33: return 'The Master Teacher - Your path is about spiritual service and healing humanity.';
      default: return 'Unknown life path meaning.';
    }
  }

  String _getDestinyMeaning(int number) {
    switch (number) {
      case 1: return 'Your destiny is to lead, innovate, and pioneer new paths as an independent achiever.';
      case 2: return 'Your destiny involves cooperation, diplomacy, and creating harmony through partnerships.';
      case 3: return 'Your destiny is to express creativity, bring joy, and inspire others through your talents.';
      case 4: return 'Your destiny involves building solid foundations, creating stability, and practical achievements.';
      case 5: return 'Your destiny embraces freedom, change, and progressive ideas that transform society.';
      case 6: return 'Your destiny involves nurturing, responsibility, and creating beauty and harmony.';
      case 7: return 'Your destiny is to seek wisdom, analyze deeply, and share spiritual understanding.';
      case 8: return 'Your destiny involves material success, leadership, and achieving abundance.';
      case 9: return 'Your destiny is humanitarian service, compassion, and making the world better.';
      case 11: return 'Your destiny involves spiritual illumination, inspired vision, and uplifting humanity.';
      case 22: return 'Your destiny is to manifest grand visions and make a significant practical impact.';
      case 33: return 'Your destiny involves master teaching, spiritual service, and healing on a large scale.';
      default: return 'Unknown destiny meaning.';
    }
  }

  Map<String, dynamic> calculateCompatibility(
      String westernSign1,
      Map<String, dynamic> numerology1,
      String westernSign2,
      Map<String, dynamic> numerology2
      ) {
    double westernScore = _calculateWesternCompatibility(westernSign1, westernSign2);
    double numerologyScore = _calculateNumerologyCompatibility(numerology1, numerology2);
    double overallScore = (westernScore * 0.7) + (numerologyScore * 0.3);

    String compatibilityLevel = _getCompatibilityLevel(overallScore);
    String description = _getCompatibilityDescription(overallScore, westernSign1, westernSign2);

    return {
      'overall_score': overallScore,
      'compatibility_level': compatibilityLevel,
      'description': description,
      'western_score': westernScore,
      'numerology_score': numerologyScore,
    };
  }

  double _calculateWesternCompatibility(String sign1, String sign2) {
    Map<String, List<String>> compatibleSigns = {
      'Aries ♈': ['Leo ♌', 'Sagittarius ♐', 'Gemini ♊', 'Aquarius ♒'],
      'Taurus ♉': ['Virgo ♍', 'Capricorn ♑', 'Cancer ♋', 'Pisces ♓'],
      'Gemini ♊': ['Libra ♎', 'Aquarius ♒', 'Aries ♈', 'Leo ♌'],
      'Cancer ♋': ['Scorpio ♏', 'Pisces ♓', 'Taurus ♉', 'Virgo ♍'],
      'Leo ♌': ['Aries ♈', 'Sagittarius ♐', 'Gemini ♊', 'Libra ♎'],
      'Virgo ♍': ['Taurus ♉', 'Capricorn ♑', 'Cancer ♋', 'Scorpio ♏'],
      'Libra ♎': ['Gemini ♊', 'Aquarius ♒', 'Leo ♌', 'Sagittarius ♐'],
      'Scorpio ♏': ['Cancer ♋', 'Pisces ♓', 'Virgo ♍', 'Capricorn ♑'],
      'Sagittarius ♐': ['Aries ♈', 'Leo ♌', 'Libra ♎', 'Aquarius ♒'],
      'Capricorn ♑': ['Taurus ♉', 'Virgo ♍', 'Scorpio ♏', 'Pisces ♓'],
      'Aquarius ♒': ['Gemini ♊', 'Libra ♎', 'Aries ♈', 'Sagittarius ♐'],
      'Pisces ♓': ['Cancer ♋', 'Scorpio ♏', 'Taurus ♉', 'Capricorn ♑'],
    };

    if (sign1 == sign2) return 0.7;

    if (compatibleSigns[sign1]?.contains(sign2) ?? false) {
      return 0.9;
    }

    return 0.5;
  }

  double _calculateNumerologyCompatibility(Map<String, dynamic> num1, Map<String, dynamic> num2) {
    double score = 0.0;

    int lifePathDiff = (num1['life_path'] - num2['life_path']).abs();
    if (lifePathDiff == 0) score += 0.3;
    else if (lifePathDiff <= 2) score += 0.2;
    else score += 0.1;

    int destinyDiff = (num1['destiny'] - num2['destiny']).abs();
    if (destinyDiff == 0) score += 0.3;
    else if (destinyDiff <= 2) score += 0.2;
    else score += 0.1;

    int soulUrgeDiff = (num1['soul_urge'] - num2['soul_urge']).abs();
    if (soulUrgeDiff == 0) score += 0.2;
    else if (soulUrgeDiff <= 2) score += 0.15;
    else score += 0.05;

    int birthdayDiff = (num1['birthday'] - num2['birthday']).abs();
    if (birthdayDiff == 0) score += 0.2;
    else if (birthdayDiff <= 2) score += 0.15;
    else score += 0.05;

    return score;
  }

  String _getCompatibilityLevel(double score) {
    if (score >= 0.8) return 'Excellent Match';
    if (score >= 0.7) return 'Great Compatibility';
    if (score >= 0.6) return 'Good Match';
    if (score >= 0.5) return 'Moderate Compatibility';
    if (score >= 0.4) return 'Challenging';
    return 'Difficult Match';
  }

  String _getCompatibilityDescription(double score, String sign1, String sign2) {
    if (score >= 0.8) {
      return 'Your connection is cosmic! $sign1 and $sign2 create magical synergy. This partnership has incredible potential for growth, harmony, and mutual support.';
    } else if (score >= 0.7) {
      return 'Great energy between $sign1 and $sign2! You complement each other well and can build a strong, supportive relationship with understanding and effort.';
    } else if (score >= 0.6) {
      return 'Good compatibility! $sign1 and $sign2 can create a balanced relationship. With communication and compromise, this partnership can thrive.';
    } else if (score >= 0.5) {
      return 'Moderate compatibility between $sign1 and $sign2. There are both challenges and opportunities for growth in this relationship.';
    } else if (score >= 0.4) {
      return 'Challenging connection between $sign1 and $sign2. This relationship requires significant effort, understanding, and compromise to succeed.';
    } else {
      return 'Difficult match between $sign1 and $sign2. Fundamental differences may create ongoing challenges, but growth is possible with tremendous effort.';
    }
  }

  Map<String, dynamic> getZodiacInfo(String zodiac) {
    final Map<String, Map<String, dynamic>> zodiacData = {
      "Aries ♈": {
        'element': 'Fire',
        'planet': 'Mars',
        'color': 'Red',
        'traits': 'Courageous, Determined, Confident, Enthusiastic, Optimistic, Passionate',
        'description': 'The pioneer and trailblazer of the horoscope wheel, Aries energy helps us initiate, fight for our beliefs and fearlessly put ourselves out there. Aries is the first sign of the zodiac, and that\'s pretty much how those born under this sign see themselves: first. Aries are the leaders of the pack, first in line to get things going.',
        'compatibility': ['Leo', 'Sagittarius', 'Gemini'],
        'lucky_numbers': [1, 9, 7],
        'best_traits': ['Courageous', 'Determined', 'Confident', 'Enthusiastic', 'Optimistic'],
        'weaknesses': ['Impatient', 'Moody', 'Short-tempered', 'Impulsive', 'Aggressive'],
        'career': ['Entrepreneur', 'Athlete', 'Pilot', 'Soldier', 'Police Officer', 'Surgeon'],
        'health': ['Headaches', 'Stress-related issues', 'Eye problems', 'Facial injuries'],
        'love': 'Aries approach love with the same passion they bring to everything else. They need a partner who can keep up with their energy and enthusiasm.',
        'friendship': 'Loyal and protective friends who will always stand up for their loved ones.',
        'symbol': 'The Ram',
        'dates': 'March 21 - April 19',
        'birthstone': 'Diamond',
        'flower': 'Honeysuckle',
        'tarot_card': 'The Emperor',
        'famous_people': ['Lady Gaga', 'Robert Downey Jr.', 'Elton John', 'Mariah Carey'],
      },
      "Taurus ♉": {
        'element': 'Earth',
        'planet': 'Venus',
        'color': 'Green, Pink',
        'traits': 'Reliable, Patient, Practical, Devoted, Responsible, Stable',
        'description': 'The persistent provider of the horoscope family, Taurus energy helps us seek security, enjoy earthly pleasures and get the job done. Taurus is an earth sign represented by the bull. Like their celestial spirit animal, Taureans enjoy relaxing in serene, bucolic environments.',
        'compatibility': ['Virgo', 'Capricorn', 'Cancer'],
        'lucky_numbers': [2, 6, 9, 12],
        'best_traits': ['Reliable', 'Patient', 'Practical', 'Devoted', 'Responsible'],
        'weaknesses': ['Stubborn', 'Possessive', 'Uncompromising', 'Resistant to change'],
        'career': ['Banker', 'Artist', 'Chef', 'Landscaper', 'Musician', 'Financial Advisor'],
        'health': ['Throat issues', 'Weight management', 'Thyroid', 'Neck problems'],
        'love': 'Taurus is a loyal and reliable partner who values stability and physical affection in relationships.',
        'friendship': 'Dependable friends who create comfortable, lasting bonds.',
        'symbol': 'The Bull',
        'dates': 'April 20 - May 20',
        'birthstone': 'Emerald',
        'flower': 'Rose, Poppy',
        'tarot_card': 'The Hierophant',
        'famous_people': ['Adele', 'Dwayne Johnson', 'William Shakespeare', 'Cher'],
      },
      "Gemini ♊": {
        'element': 'Air',
        'planet': 'Mercury',
        'color': 'Yellow, Light-Green',
        'traits': 'Versatile, Expressive, Curious, Kind, Intelligent, Quick-witted',
        'description': 'The versatile communicator of the horoscope wheel, Gemini energy helps us communicate, connect, and synthesize ideas and information. Gemini is an air sign represented by the twins.',
        'compatibility': ['Libra', 'Aquarius', 'Aries'],
        'lucky_numbers': [5, 7, 14, 23],
        'best_traits': ['Versatile', 'Expressive', 'Curious', 'Kind', 'Intelligent'],
        'weaknesses': ['Nervous', 'Inconsistent', 'Indecisive', 'Superficial'],
        'career': ['Journalist', 'Teacher', 'Salesperson', 'Writer', 'Interpreter'],
        'health': ['Nervous system', 'Lungs', 'Arms', 'Hands'],
        'love': 'Gemini needs mental stimulation and variety in relationships. They enjoy witty conversations and new experiences.',
        'friendship': 'Social butterflies who bring energy and excitement to friendships.',
        'symbol': 'The Twins',
        'dates': 'May 21 - June 20',
        'birthstone': 'Pearl',
        'flower': 'Lavender',
        'tarot_card': 'The Lovers',
        'famous_people': ['Kanye West', 'Angelina Jolie', 'Johnny Depp', 'Marilyn Monroe'],
      },
      "Cancer ♋": {
        'element': 'Water',
        'planet': 'Moon',
        'color': 'White, Silver',
        'traits': 'Intuitive, Emotional, Intelligent, Passionate, Protective, Sympathetic',
        'description': 'The natural nurturer of the horoscope wheel, Cancer energy helps us connect with our feelings, plant deep roots, and create safe, supportive environments. Cancer is a water sign represented by the crab.',
        'compatibility': ['Scorpio', 'Pisces', 'Taurus'],
        'lucky_numbers': [2, 3, 15, 20],
        'best_traits': ['Intuitive', 'Emotional', 'Intelligent', 'Passionate', 'Protective'],
        'weaknesses': ['Moody', 'Pessimistic', 'Suspicious', 'Manipulative'],
        'career': ['Chef', 'Historian', 'Interior Designer', 'Nurse', 'Real Estate Agent'],
        'health': ['Stomach', 'Breasts', 'Digestive system'],
        'love': 'Cancer seeks emotional security and deep connections. They are nurturing and devoted partners.',
        'friendship': 'Loyal and caring friends who remember every detail about your life.',
        'symbol': 'The Crab',
        'dates': 'June 21 - July 22',
        'birthstone': 'Ruby',
        'flower': 'Lily',
        'tarot_card': 'The Chariot',
        'famous_people': ['Tom Hanks', 'Princess Diana', 'Tom Cruise', 'Meryl Streep'],
      },
      "Leo ♌": {
        'element': 'Fire',
        'planet': 'Sun',
        'color': 'Gold, Yellow, Orange',
        'traits': 'Creative, Passionate, Generous, Warm-hearted, Cheerful, Humorous',
        'description': 'The dramatic performer of the horoscope wheel, Leo energy helps us shine, express ourselves authentically, and celebrate life. Leo is a fire sign represented by the lion.',
        'compatibility': ['Aries', 'Sagittarius', 'Gemini'],
        'lucky_numbers': [1, 3, 10, 19],
        'best_traits': ['Creative', 'Passionate', 'Generous', 'Warm-hearted', 'Cheerful'],
        'weaknesses': ['Arrogant', 'Stubborn', 'Lazy', 'Inflexible'],
        'career': ['Actor', 'Manager', 'Politician', 'Designer', 'CEO'],
        'health': ['Heart', 'Back', 'Spine'],
        'love': 'Leos are passionate, romantic, and generous lovers who enjoy being adored and admired.',
        'friendship': 'Loyal and generous friends who bring warmth and fun to every gathering.',
        'symbol': 'The Lion',
        'dates': 'July 23 - August 22',
        'birthstone': 'Peridot',
        'flower': 'Sunflower',
        'tarot_card': 'Strength',
        'famous_people': ['Barack Obama', 'Jennifer Lopez', 'Madonna', 'Robert De Niro'],
      },
      "Virgo ♍": {
        'element': 'Earth',
        'planet': 'Mercury',
        'color': 'Green, Brown',
        'traits': 'Loyal, Analytical, Kind, Hardworking, Practical, Helpful',
        'description': 'The systematic analyst of the horoscope wheel, Virgo energy helps us synthesize, analyze, and organize. Virgo is an earth sign represented by the goddess of wheat and agriculture.',
        'compatibility': ['Taurus', 'Capricorn', 'Cancer'],
        'lucky_numbers': [5, 14, 15, 23, 32],
        'best_traits': ['Loyal', 'Analytical', 'Kind', 'Hardworking', 'Practical'],
        'weaknesses': ['Worrying', 'Critical', 'Shy', 'Overly conservative'],
        'career': ['Accountant', 'Editor', 'Critic', 'Doctor', 'Researcher'],
        'health': ['Digestive system', 'Intestines'],
        'love': 'Virgos show love through practical actions and attention to detail. They seek stable, reliable partners.',
        'friendship': 'Helpful and reliable friends who offer practical advice and support.',
        'symbol': 'The Virgin',
        'dates': 'August 23 - September 22',
        'birthstone': 'Sapphire',
        'flower': 'Buttercup',
        'tarot_card': 'The Hermit',
        'famous_people': ['Beyoncé', 'Keanu Reeves', 'Cameron Diaz', 'Sean Connery'],
      },
      "Libra ♎": {
        'element': 'Air',
        'planet': 'Venus',
        'color': 'Pink, Green',
        'traits': 'Cooperative, Diplomatic, Gracious, Fair-minded, Social, Idealistic',
        'description': 'The harmonious平衡 of the horoscope wheel, Libra energy helps us collaborate, find compromise, and create beauty. Libra is an air sign represented by the scales.',
        'compatibility': ['Gemini', 'Aquarius', 'Leo'],
        'lucky_numbers': [4, 6, 13, 15, 24],
        'best_traits': ['Cooperative', 'Diplomatic', 'Gracious', 'Fair-minded', 'Social'],
        'weaknesses': ['Indecisive', 'Avoids confrontations', 'Self-pity', 'Lazy'],
        'career': ['Lawyer', 'Diplomat', 'Artist', 'Counselor', 'Designer'],
        'health': ['Kidneys', 'Skin', 'Lower back'],
        'love': 'Libras seek harmony and partnership in relationships. They are romantic and value beauty.',
        'friendship': 'Charming and diplomatic friends who excel at bringing people together.',
        'symbol': 'The Scales',
        'dates': 'September 23 - October 22',
        'birthstone': 'Opal',
        'flower': 'Rose',
        'tarot_card': 'Justice',
        'famous_people': ['Will Smith', 'Kim Kardashian', 'Bruno Mars', 'John Lennon'],
      },
      "Scorpio ♏": {
        'element': 'Water',
        'planet': 'Pluto, Mars',
        'color': 'Scarlet, Red, Rust',
        'traits': 'Brave, Passionate, Stubborn, Emotional, Intense, Determined',
        'description': 'The intense transformer of the horoscope wheel, Scorpio energy helps us dive deep, merge our energy, and create powerful change. Scorpio is a water sign represented by the scorpion.',
        'compatibility': ['Cancer', 'Pisces', 'Virgo'],
        'lucky_numbers': [8, 11, 18, 22],
        'best_traits': ['Brave', 'Passionate', 'Stubborn', 'Emotional', 'Intense'],
        'weaknesses': ['Suspicious', 'Manipulative', 'Resentful', 'Compulsive'],
        'career': ['Detective', 'Surgeon', 'Psychologist', 'Researcher', 'Scientist'],
        'health': ['Reproductive system', 'Bladder', 'Colon'],
        'love': 'Scorpios form intense, transformative relationships and seek deep emotional connections.',
        'friendship': 'Loyal and protective friends who form deep, lasting bonds.',
        'symbol': 'The Scorpion',
        'dates': 'October 23 - November 21',
        'birthstone': 'Topaz',
        'flower': 'Geranium',
        'tarot_card': 'Death',
        'famous_people': ['Leonardo DiCaprio', 'Julia Roberts', 'Ryan Gosling', 'Bill Gates'],
      },
      "Sagittarius ♐": {
        'element': 'Fire',
        'planet': 'Jupiter',
        'color': 'Blue',
        'traits': 'Generous, Idealistic, Great sense of humor, Adventurous, Open-minded',
        'description': 'The adventurous explorer of the horoscope wheel, Sagittarius energy inspires us to dream big, explore new horizons, and embrace freedom. Sagittarius is a fire sign represented by the archer.',
        'compatibility': ['Aries', 'Leo', 'Aquarius'],
        'lucky_numbers': [3, 7, 9, 12, 21],
        'best_traits': ['Generous', 'Idealistic', 'Great sense of humor', 'Adventurous', 'Open-minded'],
        'weaknesses': ['Promise more than can deliver', 'Impatient', 'Tactless', 'Restless'],
        'career': ['Explorer', 'Professor', 'Philosopher', 'Travel Guide', 'Publisher'],
        'health': ['Hips', 'Thighs', 'Liver'],
        'love': 'Sagittarians value freedom and adventure in relationships. They seek partners who share their love for exploration.',
        'friendship': 'Fun-loving and optimistic friends who inspire others with their enthusiasm.',
        'symbol': 'The Archer',
        'dates': 'November 22 - December 21',
        'birthstone': 'Turquoise',
        'flower': 'Carnation',
        'tarot_card': 'Temperance',
        'famous_people': ['Taylor Swift', 'Brad Pitt', 'Miley Cyrus', 'Winston Churchill'],
      },
      "Capricorn ♑": {
        'element': 'Earth',
        'planet': 'Saturn',
        'color': 'Brown, Black',
        'traits': 'Responsible, Disciplined, Self-control, Good managers, Ambitious',
        'description': 'The determined achiever of the horoscope wheel, Capricorn energy helps us set goals, work hard, and build lasting structures. Capricorn is an earth sign represented by the sea-goat.',
        'compatibility': ['Taurus', 'Virgo', 'Scorpio'],
        'lucky_numbers': [4, 8, 13, 22],
        'best_traits': ['Responsible', 'Disciplined', 'Self-control', 'Good managers', 'Ambitious'],
        'weaknesses': ['Know-it-all', 'Unforgiving', 'Condescending', 'Expect the worst'],
        'career': ['Manager', 'Engineer', 'Banker', 'Politician', 'Architect'],
        'health': ['Knees', 'Bones', 'Skin', 'Teeth'],
        'love': 'Capricorns are serious about relationships and seek stable, long-term partnerships.',
        'friendship': 'Reliable and practical friends who offer sound advice and support.',
        'symbol': 'The Sea-Goat',
        'dates': 'December 22 - January 19',
        'birthstone': 'Garnet',
        'flower': 'Carnation',
        'tarot_card': 'The Devil',
        'famous_people': ['Michelle Obama', 'Bradley Cooper', 'Elvis Presley', 'David Bowie'],
      },
      "Aquarius ♒": {
        'element': 'Air',
        'planet': 'Uranus, Saturn',
        'color': 'Light-Blue, Silver',
        'traits': 'Progressive, Original, Independent, Humanitarian, Inventive',
        'description': 'The innovative humanitarian of the horoscope wheel, Aquarius energy helps us innovate, collaborate, and advance society. Aquarius is an air sign represented by the water bearer.',
        'compatibility': ['Gemini', 'Libra', 'Sagittarius'],
        'lucky_numbers': [4, 7, 11, 22, 29],
        'best_traits': ['Progressive', 'Original', 'Independent', 'Humanitarian', 'Inventive'],
        'weaknesses': ['Runs from emotional expression', 'Temperamental', 'Uncompromising', 'Aloof'],
        'career': ['Scientist', 'Inventor', 'Astronomer', 'Social Worker', 'Technologist'],
        'health': ['Ankles', 'Circulatory system', 'Varicose veins'],
        'love': 'Aquarians value intellectual connection and freedom in relationships. They seek partners who respect their independence.',
        'friendship': 'Innovative and open-minded friends who bring unique perspectives.',
        'symbol': 'The Water Bearer',
        'dates': 'January 20 - February 18',
        'birthstone': 'Amethyst',
        'flower': 'Orchid',
        'tarot_card': 'The Star',
        'famous_people': ['Oprah Winfrey', 'Cristiano Ronaldo', 'Harry Styles', 'Ellen DeGeneres'],
      },
      "Pisces ♓": {
        'element': 'Water',
        'planet': 'Neptune, Jupiter',
        'color': 'Sea Green, Purple',
        'traits': 'Compassionate, Artistic, Intuitive, Gentle, Wise, Musical',
        'description': 'The mystical dreamer of the horoscope wheel, Pisces energy helps us connect to the divine, tap into universal wisdom, and access spirituality. Pisces is a water sign represented by two fish swimming in opposite directions.',
        'compatibility': ['Cancer', 'Scorpio', 'Taurus'],
        'lucky_numbers': [3, 9, 12, 15, 18, 24],
        'best_traits': ['Compassionate', 'Artistic', 'Intuitive', 'Gentle', 'Wise'],
        'weaknesses': ['Fearful', 'Overly trusting', 'Sad', 'Desire to escape reality'],
        'career': ['Artist', 'Musician', 'Psychologist', 'Healer', 'Marine Biologist'],
        'health': ['Feet', 'Lymphatic system', 'Immune system'],
        'love': 'Pisceans are romantic, compassionate partners who seek deep spiritual connections.',
        'friendship': 'Empathetic and compassionate friends who offer unconditional support.',
        'symbol': 'The Fish',
        'dates': 'February 19 - March 20',
        'birthstone': 'Aquamarine',
        'flower': 'Water Lily',
        'tarot_card': 'The Moon',
        'famous_people': ['Rihanna', 'Albert Einstein', 'Kurt Cobain', 'Drew Barrymore'],
      },
    };

    return zodiacData[zodiac] ?? {
      'element': 'Unknown',
      'planet': 'Unknown',
      'color': 'Unknown',
      'traits': 'Unknown',
      'description': 'No information available for this sign.',
      'compatibility': [],
      'lucky_numbers': [],
      'best_traits': [],
      'weaknesses': [],
      'career': [],
      'health': [],
      'love': 'Information not available.',
      'friendship': 'Information not available.',
      'symbol': 'Unknown',
      'dates': 'Unknown',
      'birthstone': 'Unknown',
      'flower': 'Unknown',
      'tarot_card': 'Unknown',
      'famous_people': [],
    };
  }

  List<Widget> _buildStars(BuildContext context) {
    final Random random = Random();
    return List.generate(60, (index) {
      final double top = random.nextDouble() * MediaQuery.of(context).size.height;
      final double left = random.nextDouble() * MediaQuery.of(context).size.width;
      final double size = random.nextDouble() * 3 + 1;
      final double opacity = random.nextDouble() * 0.6 + 0.2;

      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  Widget _buildTabContent(String zodiac, Map<String, dynamic> zodiacInfo) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(zodiac, zodiacInfo);
      case 1:
        return _buildNumerologyTab();
      case 2:
        return _buildCompatibilityTab(zodiac, zodiacInfo);
      case 3:
        return _buildMeditationTab();
      case 4:
        return _buildCosmicTab(zodiacInfo);
      case 5:
        return _buildDailyInsightsTab(zodiac);
      default:
        return _buildOverviewTab(zodiac, zodiacInfo);
    }
  }

  Widget _buildOverviewTab(String zodiac, Map<String, dynamic> zodiacInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAffirmationCard(),
          SizedBox(height: 16),

          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Your Sun Sign",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    zodiac,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    zodiacInfo['dates'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildQuickCompatibilityCard(zodiac),
          SizedBox(height: 16),

          _buildDailyHoroscope(),

          const SizedBox(height: 16),

          ..._buildEnhancedZodiacInfoCards(zodiacInfo),
        ],
      ),
    );
  }

  Widget _buildDailyHoroscope() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.today, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "Today's Horoscope",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Today brings new opportunities for growth and connection. "
                  "The cosmic energy supports new beginnings and meaningful conversations. "
                  "Trust your intuition and follow your heart.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildHoroscopeMetric("Mood", "😊", Colors.green),
                const SizedBox(width: 15),
                _buildHoroscopeMetric("Energy", "⚡", Colors.orange),
                const SizedBox(width: 15),
                _buildHoroscopeMetric("Luck", "🍀", Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumerologyTab() {
    Map<String, dynamic> numerology = calculateNumerology(widget.name, widget.birthDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Your Numerology Profile",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNumerologyNumber('Soul Urge', numerology['soul_urge'], Colors.purple),
                      _buildNumerologyNumber('Birthday', numerology['birthday'], Colors.blue),
                      _buildNumerologyNumber('Life Path', numerology['life_path'], Colors.green),
                      _buildNumerologyNumber('Destiny', numerology['destiny'], Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ..._buildNumerologyDetailCards(numerology),
        ],
      ),
    );
  }

  Widget _buildNumerologyNumber(String title, int number, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNumerologyDetailCards(Map<String, dynamic> numerology) {
    return [
      _buildNumerologyDetailCard(
        'Soul Urge Number',
        numerology['soul_urge'],
        numerology['soul_urge_meaning'],
        Colors.purple,
        Icons.favorite,
      ),
      const SizedBox(height: 15),
      _buildNumerologyDetailCard(
        'Birthday Number',
        numerology['birthday'],
        numerology['birthday_meaning'],
        Colors.blue,
        Icons.cake,
      ),
      const SizedBox(height: 15),
      _buildNumerologyDetailCard(
        'Life Path Number',
        numerology['life_path'],
        numerology['life_path_meaning'],
        Colors.green,
        Icons.auto_awesome,
      ),
      const SizedBox(height: 15),
      _buildNumerologyDetailCard(
        'Destiny Number',
        numerology['destiny'],
        numerology['destiny_meaning'],
        Colors.orange,
        Icons.star,
      ),
    ];
  }

  Widget _buildNumerologyDetailCard(String title, int number, String meaning, Color color, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Number $number',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meaning,
              style: const TextStyle(fontSize: 14, height: 1.4),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityTab(String zodiac, Map<String, dynamic> zodiacInfo) {
    String partnerWesternSign = "Leo ♌";
    Map<String, dynamic> partnerNumerology = calculateNumerology("Partner Name", DateTime(1990, 8, 15));

    Map<String, dynamic> compatibility = calculateCompatibility(
        zodiac,
        calculateNumerology(widget.name, widget.birthDate),
        partnerWesternSign,
        partnerNumerology
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Relationship Compatibility",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCompatibilityScore(compatibility['overall_score']),
                  const SizedBox(height: 16),
                  Text(
                    compatibility['compatibility_level'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    compatibility['description'],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.insights, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Detailed Analysis",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCompatibilityBar('Western Zodiac', compatibility['western_score'], Colors.blue),
                  _buildCompatibilityBar('Numerology', compatibility['numerology_score'], Colors.green),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        "Relationship Tips",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCompatibilityTip(
                    "Communication",
                    "Focus on open and honest communication. Share your thoughts and feelings regularly.",
                    Icons.chat,
                  ),
                  _buildCompatibilityTip(
                    "Understanding",
                    "Make an effort to understand each other's needs and perspectives.",
                    Icons.psychology,
                  ),
                  _buildCompatibilityTip(
                    "Quality Time",
                    "Spend meaningful time together and create shared experiences.",
                    Icons.favorite,
                  ),
                  _buildCompatibilityTip(
                    "Growth",
                    "Support each other's personal growth and celebrate achievements together.",
                    Icons.trending_up,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityScore(double score) {
    int percentage = (score * 100).round();
    Color color = score >= 0.8 ? Colors.green :
    score >= 0.6 ? Colors.orange :
    Colors.red;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: score,
            strokeWidth: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Column(
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Match',
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompatibilityBar(String label, double score, Color color) {
    int percentage = (score * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityTip(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meditations.length,
      itemBuilder: (context, index) {
        final meditation = _meditations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.self_improvement, color: Colors.white),
            ),
            title: Text(
              meditation.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${meditation.duration} • ${meditation.type}'),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.green),
              onPressed: () {
                // Play meditation
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCosmicTab(Map<String, dynamic> zodiacInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMoonPhaseCard(),
          const SizedBox(height: 16),

          _buildLuckyNumbersCard(),
          const SizedBox(height: 16),

          _buildCompatibilityCard(zodiacInfo),
        ],
      ),
    );
  }

  Widget _buildDailyInsightsTab(String zodiac) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        "Daily Quick Insights",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickInsight("Mood", "😊", "Positive", Colors.green),
                      _buildQuickInsight("Energy", "⚡", "High", Colors.orange),
                      _buildQuickInsight("Focus", "🎯", "Creative", Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        "Today's Simple Tip",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Take a moment to breathe deeply and set one positive intention for your day. Small mindful moments create big cosmic shifts!",
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Zodiac Quick Facts
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Your Sign Quick Facts",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildZodiacFact("Element", getZodiacInfo(zodiac)['element'], Icons.landscape),
                  _buildZodiacFact("Ruling Planet", getZodiacInfo(zodiac)['planet'], Icons.language),
                  _buildZodiacFact("Lucky Color", getZodiacInfo(zodiac)['color'], Icons.palette),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Need a quick cosmic boost?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _generateDailyAffirmation,
                    icon: Icon(Icons.auto_awesome),
                    label: Text("Get New Affirmation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsight(String title, String emoji, String value, Color color) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildZodiacFact(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonPhaseCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.nightlight_round, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Moon Phase Today",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade300, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _moonPhaseEmoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentMoonPhase,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _moonPhaseDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyNumbersCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  "Lucky Numbers & Colors",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.amber),
                  onPressed: _refreshLuckyNumbers,
                  tooltip: 'Generate new lucky numbers',
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              "Your Lucky Numbers Today:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _luckyNumbers.map((number) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text(
              "Your Lucky Colors Today:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _luckyColors.map((color) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getColorFromName(color),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    color,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getTextColorForBackground(_getColorFromName(color)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text(
              "💫 These numbers and colors are specially aligned with your energy today. Use them in decisions, games, or creative projects!",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'deep purple': return Colors.deepPurple;
      case 'royal blue': return Colors.blue.shade700;
      case 'emerald green': return Colors.green.shade600;
      case 'sunset orange': return Colors.orange.shade600;
      case 'ruby red': return Colors.red.shade600;
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey.shade400;
      case 'turquoise': return Colors.cyan;
      case 'magenta': return Colors.pink;
      case 'sapphire': return Colors.blue.shade900;
      case 'amethyst purple': return Colors.purple;
      case 'rose pink': return Colors.pink.shade300;
      case 'ocean blue': return Colors.blue.shade400;
      case 'forest green': return Colors.green.shade800;
      default: return Colors.grey;
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildCompatibilityCard(Map<String, dynamic> zodiacInfo) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink),
                SizedBox(width: 8),
                Text(
                  "Best Matches",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (zodiacInfo['compatibility'] as List).map((sign) {
                return Chip(
                  label: Text(sign),
                  backgroundColor: Colors.pink.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.pink),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoroscopeMetric(String label, String emoji, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEnhancedZodiacInfoCards(Map<String, dynamic> zodiacInfo) {
    return [
      Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    "Basic Information",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem("Symbol", zodiacInfo['symbol'], Icons.emoji_symbols),
                  _buildInfoItem("Element", zodiacInfo['element'], Icons.landscape),
                  _buildInfoItem("Planet", zodiacInfo['planet'], Icons.language),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoItem("Birthstone", zodiacInfo['birthstone'], Icons.diamond),
                  _buildInfoItem("Flower", zodiacInfo['flower'], Icons.local_florist),
                  _buildInfoItem("Tarot", zodiacInfo['tarot_card'], Icons.style),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),

      _buildTraitsCard("Best Traits", zodiacInfo['best_traits'], Colors.green, Icons.thumb_up),
      const SizedBox(height: 15),

      _buildTraitsCard("Areas to Improve", zodiacInfo['weaknesses'], Colors.orange, Icons.warning),
      const SizedBox(height: 15),

      Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.work, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Career & Health",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection("Ideal Careers", zodiacInfo['career'], Icons.business_center),
              const SizedBox(height: 12),
              _buildSection("Health Focus", zodiacInfo['health'], Icons.favorite),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),

      // Love & Friendship
      Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, color: Colors.pink),
                  SizedBox(width: 8),
                  Text(
                    "Relationships",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRelationshipSection("Love Style", zodiacInfo['love'], Icons.favorite_border),
              const SizedBox(height: 12),
              _buildRelationshipSection("Friendship Style", zodiacInfo['friendship'], Icons.people),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),

      _buildFamousPeopleCard(zodiacInfo['famous_people']),
      const SizedBox(height: 15),

      Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.description, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                zodiacInfo['description'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTraitsCard(String title, List<dynamic> traits, Color color, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: traits.map((trait) {
                return Chip(
                  label: Text(trait.toString()),
                  backgroundColor: color.withOpacity(0.1),
                  labelStyle: TextStyle(color: color),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) {
            return Chip(
              label: Text(item.toString()),
              backgroundColor: Colors.blue.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelationshipSection(String title, String description, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.pink),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFamousPeopleCard(List<dynamic> famousPeople) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  "Famous People",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: famousPeople.map((person) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    person.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int tabIndex, String label, IconData icon) {
    final isSelected = _selectedTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = tabIndex);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String zodiac = getZodiacSign(widget.birthDate);
    final Map<String, dynamic> zodiacInfo = getZodiacInfo(zodiac);

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    colors: [
                      Colors.blue.shade800,
                      Colors.purple.shade600,
                      Colors.pink.shade400,
                      Colors.blue.shade800,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                    transform: GradientRotation(_gradientController.value * 2 * pi),
                  ),
                ),
              );
            },
          ),

          // Stars
          ..._buildStars(context),

          SafeArea(
            child: Column(
              children: [
                // Header with logout option if logged in
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Zodic",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (widget.userData != null)
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await AuthService().logout();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WelcomeScreen(),
                              ),
                            );
                          },
                          tooltip: 'Logout',
                        ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    opacity: _opacity,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          margin: const EdgeInsets.all(16),
                          elevation: 25,
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            children: [
                              // Welcome Section
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutBack,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: child,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        size: 60,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Welcome, ${widget.name}!",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Your Cosmic Identity",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tabs
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildTabButton(0, 'Overview', Icons.dashboard),
                                      _buildTabButton(1, 'Numerology', Icons.numbers),
                                      _buildTabButton(2, 'Compatibility', Icons.favorite),
                                      _buildTabButton(3, 'Meditation', Icons.self_improvement),
                                      _buildTabButton(4, 'Cosmic', Icons.auto_awesome),
                                      _buildTabButton(5, 'Insights', Icons.lightbulb),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tab Content
                              Expanded(
                                child: _buildTabContent(zodiac, zodiacInfo),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyHoroscope {
  final String day;
  final String prediction;
  final int luckyNumber;

  DailyHoroscope({
    required this.day,
    required this.prediction,
    required this.luckyNumber,
  });
}

class Meditation {
  final String title;
  final String duration;
  final String type;

  Meditation({
    required this.title,
    required this.duration,
    required this.type,
  });
}

class DailyInsightsPage extends StatefulWidget {
  final String name;
  final String zodiacSign;
  final DateTime birthDate;

  const DailyInsightsPage({
    Key? key,
    required this.name,
    required this.zodiacSign,
    required this.birthDate,
  }) : super(key: key);

  @override
  State<DailyInsightsPage> createState() => _DailyInsightsPageState();
}

class _DailyInsightsPageState extends State<DailyInsightsPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  double _opacity = 0.0;

  final Map<String, String> _dailyMood = {
    'mood': 'Positive',
    'emoji': '😊',
    'description': 'Great day for social connections'
  };

  final Map<String, dynamic> _energyLevel = {
    'level': 85,
    'trend': 'rising',
    'tip': 'Your energy peaks in the afternoon'
  };

  final List<Map<String, String>> _quickTips = [
    {'icon': '💬', 'tip': 'Speak your truth today'},
    {'icon': '❤️', 'tip': 'Express gratitude to loved ones'},
    {'icon': '🌱', 'tip': 'Plant seeds for future growth'},
    {'icon': '✨', 'tip': 'Trust your intuition'},
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Timer(const Duration(milliseconds: 300), () {
      _controller.forward();
      setState(() => _opacity = 1.0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildInsightCard(String title, String emoji, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(Map<String, String> tip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(tip['icon']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip['tip']!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _opacity,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade600,
                        Colors.purple.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          const Text(
                            "Daily Insights",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.auto_awesome, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Hello, ${widget.name}!",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.zodiacSign,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Today's Energy",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildInsightCard('Mood', _dailyMood['emoji']!, _dailyMood['mood']!, Colors.green),
                            _buildInsightCard('Energy', '⚡', '${_energyLevel['level']}%', Colors.orange),
                            _buildInsightCard('Focus', '🎯', 'Creative', Colors.blue),
                            _buildInsightCard('Luck', '🍀', 'High', Colors.purple),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.description, color: Colors.deepPurple),
                                    SizedBox(width: 8),
                                    Text(
                                      "Today's Vibe",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _dailyMood['description']!,
                                  style: const TextStyle(fontSize: 14, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _energyLevel['tip']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Quick Tips for Today",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._quickTips.map((tip) => _buildTipCard(tip)).toList(),

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Refresh Insights"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
