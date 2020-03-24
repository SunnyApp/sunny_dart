//
//
//class _NumberFormatterDemo extends State {
//  final List _allActivities = ['+1', '+91'];
//  String _activity = '+1';
//  _NumberTextInputFormatter _phoneNumberFormatter =
//  _NumberTextInputFormatter(1);
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//        appBar: AppBar(
//          title: const Text('Number Formatter Demo'),
//        ),
//        body: DropdownButtonHideUnderline(
//          child: SafeArea(
//            top: false,
//            bottom: false,
//            child: ListView(
//                padding: const EdgeInsets.all(16.0),
//                children: [
//                  const SizedBox(height: 8.0),
//                  InputDecorator(
//                    decoration: const InputDecoration(
//                      labelText: 'Country Code',
//                      hintText: 'Select a country code',
//                      contentPadding: EdgeInsets.zero,
//                    ),
//                    isEmpty: _activity == null,
//                    child: DropdownButton(
//                      value: _activity,
//                      onChanged: (String newValue) {
//                        setState(() {
//                          _activity = newValue;
//                          switch(newValue){
//                            case '+1':
//                              _phoneNumberFormatter = _NumberTextInputFormatter(1);
//                              break;
//                            case '+91':
//                              _phoneNumberFormatter = _NumberTextInputFormatter(91);
//                              break;
//                          }
//                        });
//                      },
//                      items: _allActivities
//                          .map>((String value) {
//                        return DropdownMenuItem(
//                          value: value,
//                          child: Text(value),
//                        );
//                      }).toList(),
//                    ),
//                  ),
//                  const SizedBox(height: 24.0),
//                  TextFormField(
//                    decoration: const InputDecoration(
//                      border: UnderlineInputBorder(),
//                      filled: true,
//                      icon: Icon(Icons.phone),
//                      hintText: 'Where can we reach you?',
//                      labelText: 'Phone Number *',
//                    ),
//                    keyboardType: TextInputType.phone,
//                    onSaved: (String value) {},
//                    inputFormatters: [
//                      WhitelistingTextInputFormatter.digitsOnly,
//                      // Fit the validating format.
//                      _phoneNumberFormatter,
//                    ],
//                  ),
//                ]),
//          ),
//        ));
//  }
//}
//
//class _NumberTextInputFormatter extends TextInputFormatter {
//  int _whichNumber;
//  _NumberTextInputFormatter(this._whichNumber);
//
//  @override
//  TextEditingValue formatEditUpdate(
//      TextEditingValue oldValue,
//      TextEditingValue newValue,
//      ) {
//    final int newTextLength = newValue.text.length;
//    int selectionIndex = newValue.selection.end;
//    int usedSubstringIndex = 0;
//    final StringBuffer newText = StringBuffer();
//    switch (_whichNumber) {
//      case 1:
//        {
//          if (newTextLength >= 1 ) {
//            newText.write('(');
//            if (newValue.selection.end >= 1) selectionIndex++;
//          }
//          if (newTextLength >= 4 ) {
//            newText.write(
//                newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
//            if (newValue.selection.end >= 3) selectionIndex += 2;
//          }
//          if (newTextLength >= 7 ) {
//            newText.write(
//                newValue.text.substring(3, usedSubstringIndex = 6) + '-');
//            if (newValue.selection.end >= 6) selectionIndex++;
//          }
//          if (newTextLength >= 11 ) {
//            newText.write(
//                newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
//            if (newValue.selection.end >= 10) selectionIndex++;
//          }
//          break;
//        }
//      case 91:
//        {
//          if (newTextLength >= 5) {
//            newText.write(
//                newValue.text.substring(0, usedSubstringIndex = 5) + ' ');
//            if (newValue.selection.end >= 6) selectionIndex++;
//          }
//          break;
//        }
//    }
//    // Dump the rest.
//    if (newTextLength >= usedSubstringIndex)
//      newText.write(newValue.text.substring(usedSubstringIndex));
//    return TextEditingValue(
//      text: newText.toString(),
//      selection: TextSelection.collapsed(offset: selectionIndex),
//    );
//  }
//}

import 'package:libphonenumber/libphonenumber.dart';

Future<String> formatPhoneNumber(String phoneNumber, {String isoCode = ''}) async {
  return (await PhoneNumberUtil.formatAsYouType(phoneNumber: phoneNumber, isoCode: ''));
}
