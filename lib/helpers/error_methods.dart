T badArgument<T>({value, String? name, String? message}) =>
    throw ArgumentError.value(value, name, message);

T wrongType<T>(String name, value, List<Type> accepted) =>
    throw ArgumentError.value(value, name,
        "Wrong type (${value?.runtimeType}) - expected one of $accepted");
