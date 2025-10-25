import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(ZodicApp());

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
      home: AnimatedLoginPage(),
    );
  }
}

class AnimatedLoginPage extends StatefulWidget {
  @override
  _AnimatedLoginPageState createState() => _AnimatedLoginPageState();
}

class _AnimatedLoginPageState extends State<AnimatedLoginPage>
    with TickerProviderStateMixin {  // Changed to TickerProviderStateMixin
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
    super.dispose();
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
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
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AnimatedHomePage(
                name: _nameController.text,
                birthDate: _selectedDate!,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
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
          // Animated Gradient Background
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

          
          ..._buildStars(),

        
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
                                // Animated Icon
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

                              
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: "Enter your name",
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
                                          ? "Select Birth Date"
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

class AnimatedHomePage extends StatefulWidget {
  final String name;
  final DateTime birthDate;

  const AnimatedHomePage({required this.name, required this.birthDate});

  @override
  State<AnimatedHomePage> createState() => _AnimatedHomePageState();
}

class _AnimatedHomePageState extends State<AnimatedHomePage>
    with TickerProviderStateMixin {  // Changed to TickerProviderStateMixin
  late AnimationController _controller;
  late AnimationController _gradientController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _opacity = 0.0;

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

    Timer(const Duration(milliseconds: 500), () {
      _controller.forward();
      setState(() => _opacity = 1.0);
    });
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

  Map<String, dynamic> getZodiacInfo(String zodiac) {
    final Map<String, Map<String, dynamic>> zodiacData = {
      "Aries ♈": {
        'element': 'Fire',
        'planet': 'Mars',
        'color': 'Red',
        'traits': 'Courageous, Determined, Confident',
        'description': 'The pioneer and trailblazer of the horoscope wheel, Aries energy helps us initiate, fight for our beliefs and fearlessly put ourselves out there.',
      },
      "Taurus ♉": {
        'element': 'Earth',
        'planet': 'Venus',
        'color': 'Green',
        'traits': 'Reliable, Patient, Practical',
        'description': 'The persistent provider of the horoscope family, Taurus energy helps us seek security, enjoy earthly pleasures and get the job done.',
      },
      "Gemini ♊": {
        'element': 'Air',
        'planet': 'Mercury',
        'color': 'Yellow',
        'traits': 'Versatile, Expressive, Curious',
        'description': 'The most versatile and vibrant horoscope sign, Gemini energy helps us communicate, connect, and multitask with ease.',
      },
      "Cancer ♋": {
        'element': 'Water',
        'planet': 'Moon',
        'color': 'Silver',
        'traits': 'Intuitive, Emotional, Compassionate',
        'description': 'The natural nurturer of the horoscope family, Cancer energy helps us connect with our feelings, nurture ourselves and others, and build a comfortable home.',
      },
      "Leo ♌": {
        'element': 'Fire',
        'planet': 'Sun',
        'color': 'Gold',
        'traits': 'Dramatic, Outgoing, Creative',
        'description': 'The drama king and queen of the horoscope kingdom, Leo energy helps us shine, express ourselves, and celebrate life.',
      },
      "Virgo ♍": {
        'element': 'Earth',
        'planet': 'Mercury',
        'color': 'Green',
        'traits': 'Practical, Loyal, Gentle',
        'description': 'The master of practical matters, Virgo energy helps us analyze, improve, and perfect everything we touch.',
      },
      "Libra ♎": {
        'element': 'Air',
        'planet': 'Venus',
        'color': 'Pink',
        'traits': 'Social, Fair-Minded, Diplomatic',
        'description': 'The diplomat of the horoscope wheel, Libra energy helps us connect and partner with others, seek justice, and create harmony.',
      },
      "Scorpio ♏": {
        'element': 'Water',
        'planet': 'Pluto',
        'color': 'Black',
        'traits': 'Passionate, Stubborn, Resourceful',
        'description': 'The most intense and focused sign of the horoscope wheel, Scorpio energy helps us dive deep, transform, and empower ourselves.',
      },
      "Sagittarius ♐": {
        'element': 'Fire',
        'planet': 'Jupiter',
        'color': 'Purple',
        'traits': 'Extroverted, Enthusiastic, Open-Minded',
        'description': 'The adventurer of the horoscope wheel, Sagittarius energy inspires us to dream big, explore the world, and expand our minds.',
      },
      "Capricorn ♑": {
        'element': 'Earth',
        'planet': 'Saturn',
        'color': 'Brown',
        'traits': 'Serious, Independent, Disciplined',
        'description': 'The master of self-control and authority, Capricorn energy helps us set goals, take responsibility, and build lasting structures.',
      },
      "Aquarius ♒": {
        'element': 'Air',
        'planet': 'Uranus',
        'color': 'Blue',
        'traits': 'Deep, Imaginative, Original',
        'description': 'The innovator of the horoscope wheel, Aquarius energy helps us innovate, unite with others, and improve the world around us.',
      },
      "Pisces ♓": {
        'element': 'Water',
        'planet': 'Neptune',
        'color': 'Sea Green',
        'traits': 'Affectionate, Empathetic, Wise',
        'description': 'The most psychic and sensitive sign of the horoscope wheel, Pisces energy helps us connect to the spiritual, dream, and heal.',
      },
    };

    return zodiacData[zodiac] ?? {
      'element': 'Unknown',
      'planet': 'Unknown',
      'color': 'Unknown',
      'traits': 'Unknown',
      'description': 'No information available for this sign.',
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

  @override
  Widget build(BuildContext context) {
    final String zodiac = getZodiacSign(widget.birthDate);
    final Map<String, dynamic> zodiacInfo = getZodiacInfo(zodiac);

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

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          elevation: 25,
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Zodiac Icon
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
                                    size: 80,
                                    color: Colors.amber,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                
                                Text(
                                  "Welcome, ${widget.name}!",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Your Cosmic Identity",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 30),

                                
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.deepPurple, Colors.pinkAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Your Sun Sign is",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        zodiac,
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                
                                ..._buildZodiacInfoCards(zodiacInfo),

                                const SizedBox(height: 30),

                               
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text("Back"),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 15),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          
                                        },
                                        icon: const Icon(Icons.share),
                                        label: const Text("Share"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 15),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
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

  List<Widget> _buildZodiacInfoCards(Map<String, dynamic> zodiacInfo) {
    return [
      _buildInfoCard("Element", zodiacInfo['element'], Icons.landscape),
      const SizedBox(height: 15),
      _buildInfoCard("Ruling Planet", zodiacInfo['planet'], Icons.language),
      const SizedBox(height: 15),
      _buildInfoCard("Lucky Color", zodiacInfo['color'], Icons.palette),
      const SizedBox(height: 15),
      _buildInfoCard("Key Traits", zodiacInfo['traits'], Icons.psychology),
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

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
