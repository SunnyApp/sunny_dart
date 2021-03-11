abstract class SunnyGet {
  T call<T>();
  T get<T>({dynamic context, String? name});
}

class _NullSunnyGet implements SunnyGet {
  const _NullSunnyGet();
  @override
  T get<T>({dynamic context, String? name}) => call<T>();
  @override
  T call<T>() =>
      throw "No SunnyGet registered. Your application must register a SunnyGet to be able to resolve core services";
}

SunnyGet _sunny = _NullSunnyGet();
SunnyGet get sunny => _sunny;

set sunny(SunnyGet sunny) {
  _sunny = sunny;
}
