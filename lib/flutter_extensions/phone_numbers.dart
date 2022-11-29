import 'package:phone_numbers_parser/phone_numbers_parser.dart';

Future<String> formatPhoneNumber(String phoneNumber,
    {String isoCode = '', bool withDashes = true}) async {
  var parsed = PhoneNumber.parse(phoneNumber);
  if (!parsed.isValidLength() && withDashes) {
    var pn = PhoneNumber(isoCode: parsed.isoCode, nsn: '${parsed.nsn}0');

    if (pn.getFormattedNsn().endsWith("-0")) {
      return '${parsed.getFormattedNsn()}-';
    }
  }
  return parsed.getFormattedNsn();
}
