import 'dart:io';

import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/profile_repo.dart';
import 'package:fitopia/model/profile_summary_model.dart';
import 'package:fitopia/model/more_menue_model.dart';
import 'package:fitopia/presentation/Mixins/size.dart';
import 'package:fitopia/presentation/resources/index_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';

class MoreView extends StatefulWidget {
  final int refreshKey;

  const MoreView({super.key, this.refreshKey = 0});

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  final ProfileRepo _profileRepo = ProfileRepo(apiClient: ApiClient());
  ProfileSummary? _profileSummary;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfileSummary();
  }

  @override
  void didUpdateWidget(covariant MoreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey &&
        widget.refreshKey == 4) {
      _loadProfileSummary();
    }
  }

  Future<void> _loadProfileSummary() async {
    try {
      final summary = await _profileRepo.getSummary();
      if (!mounted) {
        return;
      }

      setState(() {
        _profileSummary = summary;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _profileSummary = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_isUploadingPhoto) {
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (image == null || !mounted) {
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final response = await _profileRepo.uploadProfilePhoto(File(image.path));
      final uploadedUser = response['data'];
      if (uploadedUser is Map) {
        final storage = GetStorage();
        final existing = storage.read('user_data');
        final userData = <String, dynamic>{
          if (existing is Map) ...Map<String, dynamic>.from(existing),
          ...Map<String, dynamic>.from(uploadedUser),
        };
        await storage.write('user_data', userData);
      }
      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          ClipPath(
            clipper: ProsteBezierCurve(
              position: ClipPosition.bottom,
              list: [
                BezierCurveSection(
                  start: Offset(0, 200),
                  top: Offset(AppSize.sizeWidth(context) / 2, 150),
                  end: Offset(AppSize.sizeWidth(context), 200),
                ),
              ],
            ),
            child: Container(
              height: 200,
              color: ColorManager.secondryTwo,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 200 - 175, left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ActiveProgress(
                      "Active",
                      _activeValue,
                      _activeUnit,
                    ),
                    imageWidget(),
                    ActiveProgress(
                      "Progress",
                      _progressValue,
                      _profileSummary?.progressUnit ?? 'Kgs',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            child: Container(
              //color: Colors.red,
              child: ListView.builder(
                  itemCount: moreList.length,
                  itemBuilder: (context, index) {
                    return moreListTile(moreList[index], () {
                      print(index);

                      switch (index) {
                        case 0:
                          Navigator.pushNamed(
                              context, Routes.myProfilePageRoute);
                          break;
                        case 1:
                          Navigator.pushNamed(
                              context, Routes.myProgramPageRoute);
                          break;
                        case 2:
                          Navigator.pushNamed(
                              context, Routes.myMealsPlansPageRoute);
                          break;
                        case 3:
                          Navigator.pushNamed(context, Routes.receipePageRoute);
                          break;
                        case 4:
                          Navigator.pushNamed(
                              context, Routes.nutritionPageRoute);
                          break;
                        case 5:
                          Navigator.pushNamed(context, Routes.ebookPageRoute);
                          break;
                        case 6:
                          Navigator.pushNamed(
                              context, Routes.SettingsPageRoute);
                          break;
                        case 7:
                          Navigator.pushNamed(context, Routes.chatPageRoute);
                          break;
                        case 8:
                          Navigator.pushNamed(context, Routes.helpPageRoute);
                          break;
                        case 9:
                          Navigator.pushNamed(context, Routes.logoutPageRoute);
                          break;
                        default:
                      }
                    });
                  }),
            ),
          )
        ],
      ),
    );
  }

  String get _activeValue {
    if (_profileSummary == null) {
      return '--';
    }
    return _profileSummary!.activeDays.split(' ').first;
  }

  String get _activeUnit {
    if (_profileSummary == null) {
      return 'Days';
    }
    return _profileSummary!.activeDays.split(' ').skip(1).join(' ');
  }

  String get _progressValue {
    final summary = _profileSummary;
    if (summary == null) {
      return '--';
    }
    final value = summary.progressValue % 1 == 0
        ? summary.progressValue.toStringAsFixed(0)
        : summary.progressValue.toStringAsFixed(1);
    return '$value KG';
  }

  Widget imageWidget() {
    final userData = GetStorage().read('user_data');
    final firstName =
        userData is Map ? userData['first_name']?.toString() : null;
    final lastName = userData is Map ? userData['last_name']?.toString() : null;
    final fullName = [firstName, lastName]
        .where((name) => name != null && name.trim().isNotEmpty)
        .join(' ')
        .trim();

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: GestureDetector(
            onTap: _uploadProfilePhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _profileAvatar(),
                if (_isUploadingPhoto)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                if (!_isUploadingPhoto)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: 3.0),
      Text(fullName.isEmpty ? "User" : fullName,
          style: getmediumStyle(
              color: ColorManager.whiteColor, fontSize: AppSize.s13.mv)),
      SizedBox(height: 3.0),
      Row(
        children: [
          Image.asset(ImageAssets.crownIcon, height: 10, width: 10),
          SizedBox(width: 6.0),
          Text("Premium",
              style: getmediumStyle(
                  color: ColorManager.whiteColor, fontSize: AppSize.s8.mv)),
        ],
      ),
    ]);
  }

  Widget _profileAvatar() {
    final userData = GetStorage().read('user_data');
    final imageUrl = resolveProfileImageUrl(
      userData is Map ? userData['profile_image'] : null,
    );
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 40,
      backgroundImage: AssetImage(ImageAssets.userStoreImge1),
    );
  }

  Widget ActiveProgress(String txt1, String txt2, String txt3) {
    return Column(
      children: [
        Text(txt1,
            style: getRegularStyle(
                color: ColorManager.whiteColor, fontSize: AppSize.s13.mv)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(txt2,
              style: getmediumStyle(
                  color: ColorManager.whiteColor, fontSize: AppSize.s16.mv)),
        ),
        Text(txt3,
            style: getRegularStyle(
                color: ColorManager.whiteColor, fontSize: AppSize.s13.mv)),
      ],
    );
  }

  Widget moreListTile(MoreModel? model, Function()? onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SvgPicture.asset(model!.iconPath!),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                model.title ?? "",
                style: getRegularStyle(
                    color: ColorManager.blackColor, fontSize: AppSize.s14.mv),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
