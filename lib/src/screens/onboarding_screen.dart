import 'package:e_kafel/src/models/onboarding_page_model.dart';
import 'package:e_kafel/src/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart'; // لاستخدام مؤشر النقاط
import 'package:shared_preferences/shared_preferences.dart'; // لتخزين حالة الظهور

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required Future<Null> Function() onboardingComplete,
  });

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0; // لتتبع الصفحة الحالية لمؤشر النقاط

  // بيانات صفحات الترحيب بناءً على الصور التي أرفقتها
  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      imagePath: 'assets/images/onboarding_icon1.jpg', // مسار الأيقونة الأولى
      description:
          'A Person That Undertakes To Bear Responsibility For Another Party In A Particular Situation, Whether The Responsibility Is Financial, Legal, Social Or Administrative', // النص الوصفي
      backgroundColor: Color(0xFFFDEEF7), // لون وردي فاتح من تصميمك
    ),
    OnboardingPageModel(
      imagePath: 'assets/images/onboarding_icon2.jpg', // مسار الأيقونة الثانية
      description:
          'The organization\'s process of obtaining information about orphans from various sources with the aim of compiling it into a single application.', // النص الوصفي
      backgroundColor: Color(0xFFFDEEF7), // لون وردي فاتح
    ),
    OnboardingPageModel(
      imagePath: 'assets/images/onboarding_icon3.jpg', // مسار الأيقونة الثالثة
      description:
          'It Is The Organization And Coordination Of Charitable, Financial And Administrative Efforts To Provide The Basic Needs Of Orphans.', // النص الوصفي
      backgroundColor: Color(0xFFFDEEF7), // لون وردي فاتح
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

  // دالة للانتقال إلى شاشة تسجيل الدخول وحفظ أن المستخدم رأى شاشات الترحيب
  void _goToLoginScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true); // حفظ الحالة
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        // استخدام Stack لوضع زر SKIP فوق PageView
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
                      Image.asset(_pages[index].imagePath, height: 200),
                      SizedBox(height: 40),
                      Text(
                        _pages[index].description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
          // زر SKIP في الأعلى يمين
          Positioned(
            top: 50, // مسافة من الأعلى
            right: 20, // مسافة من اليمين
            child: TextButton(
              onPressed: _goToLoginScreen,
              child: Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.pink[400], // لون يتناسب مع تصميمك
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // مؤشر النقاط في الأسفل
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: DotsIndicator(
                dotsCount: _pages.length,
                position: _currentPage.toDouble(), // تحديد النقطة النشطة
                decorator: DotsDecorator(
                  color: Colors.pink[200]!, // لون النقطة غير النشطة
                  activeColor: Colors.pink[400]!, // لون النقطة النشطة
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
