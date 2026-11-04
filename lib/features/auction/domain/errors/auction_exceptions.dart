sealed class AuctionException implements Exception {
  const AuctionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuctionValidationException extends AuctionException {
  const AuctionValidationException(super.message);
}

class AuctionAuthorizationException extends AuctionException {
  const AuctionAuthorizationException(super.message);
}

class AuctionTransitionException extends AuctionException {
  const AuctionTransitionException(super.message);
}
