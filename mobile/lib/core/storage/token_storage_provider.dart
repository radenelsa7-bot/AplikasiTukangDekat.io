import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
