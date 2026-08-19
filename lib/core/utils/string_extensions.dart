extension StringPresentation on String {
  String get humanized {
    if (isEmpty) return this;
    final words = replaceAll('_', ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }

  String get firstLetter => isEmpty ? '' : this[0].toUpperCase();

  String get initials {
    final parts = trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.firstLetter;
    return '${parts.first.firstLetter}${parts.last.firstLetter}';
  }
}
