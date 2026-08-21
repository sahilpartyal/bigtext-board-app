enum DisplayMode {
  simple,
  business,
  presentation;

  String get label {
    switch (this) {
      case DisplayMode.simple:
        return 'Basic';
      case DisplayMode.business:
        return 'Pro';
      case DisplayMode.presentation:
        return 'Premium';
    }
  }

  String get description {
    switch (this) {
      case DisplayMode.simple:
        return 'Clean simple display for everyday use';
      case DisplayMode.business:
        return 'Full control with custom branding & layouts';
      case DisplayMode.presentation:
        return 'Multi-slide displays for events & gatherings';
    }
  }
}
