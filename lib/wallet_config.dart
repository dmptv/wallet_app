import 'package:flutter_riverpod/flutter_riverpod.dart';

// Public Blockscout instance (Ethereum mainnet), no API key required.
const blockscoutBaseUrl = 'https://eth.blockscout.com/api/v2';

// A well-known, publicly active address, used as the default "watched
// wallet" so balance and transaction history have real, non-trivial data.
final watchedAddressProvider = Provider<String>((ref) {
  return '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';
});
