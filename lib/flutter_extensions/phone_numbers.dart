import 'package:libphonenumber2/libphonenumber2.dart';

Future<String> formatPhoneNumber(String phoneNumber,
    {String isoCode = ''}) async {
  return (await PhoneNumberUtil.formatAsYouType(
      phoneNumber: phoneNumber, isoCode: ''));
}
