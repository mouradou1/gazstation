class RepositoryError {
  const RepositoryError({
    required this.context,
    required this.message,
    this.title = 'Erreur serveur',
  });

  final String context;
  final String title;
  final String message;
}

typedef RepositoryErrorReporter = void Function(RepositoryError error);
