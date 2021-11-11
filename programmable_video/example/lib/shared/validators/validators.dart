abstract class StringValidator {
  bool isValid(String? value);
}

class NonEmptyStringValidator implements StringValidator {
  @override
  bool isValid(String? value) {
    if (value == null) {
      return false;
    }
    return value.isNotEmpty;
  }
}
