import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';

enum ButtonWidgetType {
  loginText,
  continueText,
  createAccountTitle,
  editProfileText,
  settingText,
  followingText,
  startTripTitle,
  endTripTitle
}

class ButtonWidget extends StatefulWidget {
  final ButtonWidgetType btnType;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final Color? fullColor;

  const ButtonWidget({
    super.key,
    required this.btnType,
    required this.onPressed,
    required this.borderColor,
    required this.textColor,
    required this.fullColor
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    String btnTitle;
    switch (widget.btnType) {
      case ButtonWidgetType.loginText:
        btnTitle = login_title;
        break;
      case ButtonWidgetType.continueText:
        btnTitle = continue_text;
        break;
      case ButtonWidgetType.createAccountTitle:
        btnTitle = create_account;
        break;
      case ButtonWidgetType.editProfileText:
        btnTitle = edit_profile;
        break;
      case ButtonWidgetType.followingText:
        btnTitle = following;
        break;
      case ButtonWidgetType.settingText:
        btnTitle = settings;
        break;
      case ButtonWidgetType.startTripTitle:
        btnTitle = start_trip;
        break;
      case ButtonWidgetType.endTripTitle:
        btnTitle = end_trip;
        break;
      default:
        btnTitle = "unknow";
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: SizedBox(
            width: vw(context, 100),
            height: vh(context, 5),
            child: Container(
              decoration: BoxDecoration(
                color:  widget.fullColor ,
                border: Border.all(color: widget.borderColor!),
                borderRadius: BorderRadius.circular(15)
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0XFF000000),
          
            ),
            onPressed: widget.onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(btnTitle, style: TextStyle(color:  widget.textColor!, fontFamily: 'KadawBold'),),
              ],
            ) 
          ),
        ),
      ],
    );
  }
}
