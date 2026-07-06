import 'package:provider_contract/provider_contract.dart';
import '../auth/kugou_session.dart';

final class KugouProfileMapper {
  ProviderAccountProfile map(KugouSession session,
      {required String displayName, Uri? avatarUrl}) {
    return ProviderAccountProfile(
      accountId: session.userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
