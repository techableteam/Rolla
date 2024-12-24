import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:RollaTravel/src/utils/index.dart';

class DropPinScreen extends ConsumerStatefulWidget {
  const DropPinScreen({super.key});
  @override
  ConsumerState<DropPinScreen> createState() => DropPinScreenState();
}

class DropPinScreenState extends ConsumerState<DropPinScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (mounted) {
        setState(() {
          this.keyboardHeight = keyboardHeight;
        });
      } 
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  Widget buildInstructionItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline, // Use baseline alignment
        textBaseline: TextBaseline.alphabetic, // Specify the baseline alignment
        children: [
          Text(
            '$number. ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Kadaw'
            ),
          ),
          Expanded(
            child: RichText(
              text: _buildTextWithImage(text),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildTextWithImage(String text) {
    List<InlineSpan> children = [];
    final parts = text.split('\u{1F698}');

    for (int i = 0; i < parts.length; i++) {
      // Add the text part
      if (parts[i].isNotEmpty) {
        children.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontFamily: 'Kadaw'
          ),
        ));
      }

      // Add the image if not the last part
      if (i != parts.length - 1) {
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Image.asset(
              'assets/images/icons/home.png', // Ensure this path is correct
              width: 20,
              height: 20,
            ),
          ),
        ));
      }
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: vhh(context, 3),),
              // Logo at the top
              Align(
                alignment: Alignment.topLeft,
                child: Image.asset(
                  'assets/images/icons/logo.png',
                  width: vww(context, 20),
                ),
              ),
              SizedBox(height: vhh(context, 8)),
              
              // Note text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // Adjust the value as needed
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black, // Set the text color
                      fontFamily: 'KadawBold'
                    ),
                    children: [
                      const TextSpan(
                        text: 'Note: You must start trip under the '
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Adjust spacing if needed
                          child: Image.asset(
                            'assets/images/icons/home.png',
                            width: 20, // Adjust the size to fit well with the text
                            height: 20,
                          ),
                        ),
                      ),
                      const TextSpan(
                        text: ' button before you can drop a pin and post your map.',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: vhh(context, 10)),
              
              // Instructions list
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInstructionItem(1, 'Navigate to \u{1F698} button.'),
                  buildInstructionItem(2, 'Tap "Start Trip".'),
                  buildInstructionItem(3, 'Navigate back here, to the "Drop Pin" tab.'),
                  buildInstructionItem(4, 'Upload photo and drop it on your map.'),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }

}