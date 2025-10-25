import 'package:e_kafel/src/models/onboarding_page_model.dart';
import 'package:e_kafel/src/screens/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onboardingComplete;

  const OnboardingScreen({
    super.key,
    required this.onboardingComplete,
  });

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      imagePath: 'assets/images/onboarding_icon1.jpg',
      description:
          'A Person That Undertakes To Bear Responsibility For Another Party In A Particular Situation, Whether The Responsibility Is Financial, Legal, Social Or Administrative',
      backgroundColor: Color(0xFFFDEEF7),
    ),
    OnboardingPageModel(
      imagePath: 'assets/images/onboarding_icon2.jpg',
      description:
          'The organization\'s process of obtaining information about orphans from various sources with the aim of compiling it into a single application.',
      backgroundColor: Color(0xFFFDEEF7),
    ),
    OnboardingPageModel(
      imagePath: 'assets/images/onboarding_icon3.jpg',
      description:
          'It Is The Organization And Coordination Of Charitable, Financial And Administrative Efforts To Provide The Basic Needs Of Orphans.',
      backgroundColor: Color(0xFFFDEEF7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLoginScreen() async {
    await widget.onboardingComplete();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Container(
                color: _pages[index].backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // استبدل هذا بمكون الصورة الفعلي عندما تكون الصور متاحة
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                      ),
                      // Image.asset(_pages[index].imagePath, height: 200),
                      const SizedBox(height: 40),
                      Text(
                        _pages[index].description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _goToLoginScreen,
              child: Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.pink[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: DotsIndicator(
                dotsCount: _pages.length,
                position: _currentPage,
                decorator: DotsDecorator(
                  color: Colors.pink[200]!,
                  activeColor: Colors.pink[400]!,
                  size: const Size.square(9.0),
                  activeSize: const Size(18.0, 9.0),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
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