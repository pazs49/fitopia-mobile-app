import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';

import '../resources/index_manager.dart';

class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = GetStorage().read('user_data');
    final data = userData is Map ? userData : <String, dynamic>{};
    final firstName = _value(data, 'first_name');
    final lastName = _value(data, 'last_name');
    final fullName =
        [firstName, lastName].where((name) => name.isNotEmpty).join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.greyBoxColor,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SvgPicture.asset(
              ImageAssets.arrowBack,
              color: ColorManager.blackColor,
            ),
          ),
        ),
        title: Text(
          "My Profile",
          style: getboldStyle(
            color: ColorManager.blackColor,
            fontSize: AppSize.s16,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: ColorManager.greylightColor,
              child: SvgPicture.asset(
                ImageAssets.userCircleIcon,
                color: ColorManager.greyColor,
                width: 58,
                height: 58,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              fullName.isEmpty ? 'User' : fullName,
              textAlign: TextAlign.center,
              style: getboldStyle(
                color: ColorManager.blackColor,
                fontSize: AppSize.s18,
              ),
            ),
            const SizedBox(height: 24),
            _infoTile(Icons.email_outlined, 'Email', _value(data, 'email')),
            _infoTile(
              Icons.person_outline,
              'Username',
              _value(data, 'username'),
            ),
            _infoTile(
              Icons.phone_outlined,
              'Phone',
              _value(data, 'phone_number'),
            ),
          ],
        ),
      ),
    );
  }

  static String _value(Map data, String key) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? 'Not provided' : value;
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: ColorManager.secondry),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
