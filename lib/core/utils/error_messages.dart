import '../../data/api/api_exception.dart';

String userFacingError(Object error) {
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}
