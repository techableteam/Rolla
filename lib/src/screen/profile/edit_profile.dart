import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/profile/garage_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:ui';
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final logger = Logger();
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 4;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  int? userId;
  String? _base64Image;
  bool _isLoading = false;
  bool _ischangeimage = false;
  
  String? imageUrl;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController garageController = TextEditingController();
  final TextEditingController placeController = TextEditingController();

  

  bool _showSaveButton = false;

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

    usernameController.text = GlobalVariables.userName!;
    nameController.text = GlobalVariables.realName!;
    if (GlobalVariables.bio != null){
      bioController.text = GlobalVariables.bio!;
    } 
    if (GlobalVariables.garage != null){
      garageController.text = GlobalVariables.garage!;
    } 
    if (GlobalVariables.happyPlace != null){
      placeController.text = GlobalVariables.happyPlace!;
    } 
    

    usernameController.addListener(_onTextChanged);
    nameController.addListener(_onTextChanged);
    bioController.addListener(_onTextChanged);
    garageController.addListener(_onTextChanged);
    placeController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    super.dispose();
    usernameController.removeListener(_onTextChanged);
    nameController.removeListener(_onTextChanged);
    bioController.removeListener(_onTextChanged);
    garageController.removeListener(_onTextChanged);
    placeController.removeListener(_onTextChanged);
    usernameController.dispose();
    nameController.dispose();
    bioController.dispose();
    garageController.dispose();
    placeController.dispose();
  }
  
  void _onTextChanged() {
    if (!_showSaveButton) {
      setState(() {
        if (usernameController.text != GlobalVariables.userName) {
          _showSaveButton = true;
          GlobalVariables.userName = usernameController.text;
        }
        if (nameController.text != GlobalVariables.realName) {
          _showSaveButton = true;
          GlobalVariables.realName = nameController.text;
        }
        if (bioController.text != GlobalVariables.bio) {
          _showSaveButton = true;
          GlobalVariables.bio = bioController.text;
        }
        if (garageController.text != GlobalVariables.garage) {
          _showSaveButton = true;
          GlobalVariables.garage = garageController.text;
        }
        if (placeController.text != GlobalVariables.happyPlace) {
          _showSaveButton = true;
          GlobalVariables.happyPlace = placeController.text;
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  Future<void> setPhotoUrl() async {
    setState(() {
      _ischangeimage = true;
    });
    final apiService = ApiService();
    imageUrl = await apiService.getImageUrl(_base64Image!);
    setState(() {
      _ischangeimage = false;
    });
    
  }

  Future<void> _showPicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo', style: TextStyle(fontFamily: 'Kadaw'),),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setState(() {
                      _selectedImage = photo;
                      _showSaveButton = true;
                    });
                    File imageFile = File(photo.path);
                    List<int> imageBytes = await imageFile.readAsBytes();
                    String base64String = base64Encode(imageBytes);
                    setState(() {
                      _base64Image = base64String;
                    });
                    await setPhotoUrl();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Kadaw'),),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? galleryImage = await _picker.pickImage(source: ImageSource.gallery);
                  if (galleryImage != null) {
                    setState(() {
                      _selectedImage = galleryImage;
                      _showSaveButton = true;
                    });
                    File imageFile = File(galleryImage.path);
                    List<int> imageBytes = await imageFile.readAsBytes();
                    String base64String = base64Encode(imageBytes);
                    setState(() {
                      _base64Image = base64String;
                    });
                    await setPhotoUrl();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final apiService = ApiService();
    
    final updatedName = nameController.text.trim().split(' ');
    final firstName = updatedName.isNotEmpty ? updatedName.first : '';
    final lastName = updatedName.length > 1 ? updatedName.last : '';

    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await apiService.updateUser(
        userId: GlobalVariables.userId!,
        firstName: firstName,
        lastName: lastName,
        rollaUsername: usernameController.text.trim(),
        happyPlace: placeController.text.trim(),
        photo: imageUrl ?? '',
        bio: bioController.text.trim(),
        garage: garageController.text.trim(),
      );

      if (response['statusCode'] != false) {
        // Save the updated data locally
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userData', jsonEncode(response['data']));

        // Provide success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        GlobalVariables.realName = nameController.text.toString();
        GlobalVariables.userName = usernameController.text.toString();
        if(imageUrl != null){
          GlobalVariables.userImageUrl = imageUrl.toString();
        }
        
        GlobalVariables.bio = bioController.text.toString();
        GlobalVariables.garage = garageController.text.toString();
        GlobalVariables.happyPlace = placeController.text.toString();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['message']}')),
        );
      }
    } catch (e) {
      logger.e('Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while saving changes.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _showSaveButton = false;
      });
    }
  }

  void onGarageClicked(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => const GarageScreen()));
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: FocusScope(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: vhh(context, 90),
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: kColorWhite,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: vhh(context, 10)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                              },
                              child: Image.asset(
                                'assets/images/icons/allow-left.png',
                                width: vww(context, 5),
                              ),
                            ),
                            
                            const Text(edit_profile, style: TextStyle(color: kColorBlack, fontSize: 18, fontFamily: 'KadawBold'),),

                            Container(),
                          ],
                        ),

                        SizedBox(height: vhh(context, 1)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: kColorGrey,
                                borderRadius: BorderRadius.circular(200),
                                border: Border.all(
                                    color: kColorHereButton, width: 2),
                                    image: _selectedImage != null
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(_selectedImage!.path),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : GlobalVariables.userImageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(GlobalVariables.userImageUrl!), // Use NetworkImage for URL
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: vhh(context, 1)),
                        GestureDetector(
                          onTap: () {
                            _showPicker(context);
                          },
                          child: const Text(
                            'Change Profile Photo',
                            style: TextStyle(
                              color: Colors.black, // Replace with `kColorBlack` if defined
                              fontSize: 18,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Kadaw'
                            ),
                          ),
                        ),
                        if (_ischangeimage)
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Changing user avatar now...'),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: vhh(context, 2),),
                        const Divider(color: kColorGrey, thickness: 1),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  edit_profile_username,
                                  style: TextStyle(color: kColorGrey, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Kadaw'),
                                ),
                                SizedBox(
                                  width: 200, // Adjust width as needed
                                  height: 25,
                                  child: TextField(
                                    controller: usernameController,
                                    textAlign: TextAlign.right,
                                    keyboardType: TextInputType.emailAddress,
                                    maxLines: 1, // Restrict to a single line
                                    maxLength: 20,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none, // Remove underline
                                      contentPadding: EdgeInsets.only(bottom: 14),
                                      counterText: '', // Removes the counter text (10/10)
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black, // Replace with kColorBlack
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Kadaw'
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: kColorGrey, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  edit_profile_name,
                                  style: TextStyle(color: kColorGrey, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Kadaw'),
                                ),
                                SizedBox(
                                  width: 200, // Adjust width as needed
                                  height: 25,
                                  child: TextField(
                                    controller: nameController,
                                    textAlign: TextAlign.right,
                                    maxLines: 1, // Restrict to a single line
                                    maxLength: 20,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none, // Remove underline
                                      contentPadding: EdgeInsets.only(bottom: 14),
                                      counterText: '', // Removes the counter text (10/10)
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black, // Replace with kColorBlack
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Kadaw'
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: kColorGrey, thickness: 1),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  edit_profile_bio,
                                  style: TextStyle(color: kColorGrey, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Kadaw'),
                                ),
                                SizedBox(
                                  width: 200, // Adjust width as needed
                                  height: 25,
                                  child: TextField(
                                    controller: bioController,
                                    textAlign: TextAlign.right,
                                    maxLines: 1, // Restrict to a single line
                                    maxLength: 20,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none, // Remove underline
                                      contentPadding: EdgeInsets.only(bottom: 11,),
                                      hintText: "Your Bio",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Kadaw'
                                      ),
                                      counterText: '', // Removes the counter text (10/10)
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black, // Replace with kColorBlack
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Kadaw'
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: vhh(context, 5)),
                            const Divider(color: kColorGrey, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  edit_profile_garage,
                                  style: TextStyle(color: kColorGrey, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Kadaw'),
                                ),
                                GlobalVariables.garageLogoUrl != null && GlobalVariables.garageLogoUrl!.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        onGarageClicked(); // This will always work regardless of the logo URL's value
                                      },
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: Image.network(
                                          GlobalVariables.garageLogoUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        onGarageClicked(); // Allow onTap to trigger even if no logo is present
                                      },
                                      child: const Text("    "),
                                    ),
                              ],
                            ),
                            const Divider(color: kColorGrey, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  edit_profile_happy_place,
                                  style: TextStyle(color: kColorGrey, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Kadaw'),
                                ),
                                SizedBox(
                                  width: 200, // Adjust width as needed
                                  height: 25,
                                  child: TextField(
                                    controller: placeController,
                                    textAlign: TextAlign.right,
                                    maxLines: 1, // Restrict to a single line
                                    maxLength: 20,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none, // Remove underline
                                      contentPadding: EdgeInsets.only(bottom: 11),
                                      counterText: '', // Removes the counter text (10/10)
                                      hintText: "Your Happy Place",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Kadaw'
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black, // Replace with kColorBlack
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Kadaw'
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: kColorGrey, thickness: 1),
                            if (_isLoading)
                              BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Updating changed data now...'),
                                    ],
                                  ),
                                ),
                              ),
                            // if (_showSaveButton)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _saveChanges();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kColorHereButton, // Customize as needed
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                                  ),
                                  child: const Text(
                                    'Update',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Kadaw'),
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
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
    
  }

}
