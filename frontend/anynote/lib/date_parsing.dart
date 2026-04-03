DateTime? parseAppApiDate(dynamic raw) {
  if (raw == null) {
    return null;
  }

  return DateTime.parse(raw as String).toLocal();
}
