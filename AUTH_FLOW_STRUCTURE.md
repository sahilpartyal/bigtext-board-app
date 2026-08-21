# Auth Flow Structure

This project now has the initial GetX + MVC-style auth foundation for:

- Splash screen
- Login screen
- Signup screen
- Home screen placeholder

## Current Flow

```text
Splash -> Login -> Signup -> Home
```

## Architecture

Recommended project pattern used here:

- `View`: screens and reusable UI widgets
- `Controller`: screen logic and state with GetX
- `Repository`: auth/data flow
- `Service`: local storage and future API integration
- `Model`: app data structures

## Folder Structure

```text
lib/
  app/
    routes/
      app_pages.dart
      app_routes.dart

  data/
    models/
      user_model.dart
    repositories/
      auth_repository.dart
    services/
      storage_service.dart

  modules/
    splash/
      controllers/
        splash_controller.dart
      views/
        splash_screen.dart

    auth/
      controllers/
        auth_controller.dart
      views/
        login_screen.dart
        signup_screen.dart

    home/
      views/
        home_screen.dart

  widgets/
    common_button.dart
    common_text_field.dart

  app.dart
  main.dart
```

## Files Created For This Phase

### Core App Setup

- `lib/main.dart`
- `lib/app.dart`
- `lib/app/routes/app_routes.dart`
- `lib/app/routes/app_pages.dart`

### Data Layer

- `lib/data/models/user_model.dart`
- `lib/data/services/storage_service.dart`
- `lib/data/repositories/auth_repository.dart`

### Controllers

- `lib/modules/auth/controllers/auth_controller.dart`
- `lib/modules/splash/controllers/splash_controller.dart`

### Views

- `lib/modules/splash/views/splash_screen.dart`
- `lib/modules/auth/views/login_screen.dart`
- `lib/modules/auth/views/signup_screen.dart`
- `lib/modules/home/views/home_screen.dart`

### Reusable Widgets

- `lib/widgets/common_button.dart`
- `lib/widgets/common_text_field.dart`

## Screen Responsibilities

### Splash Screen

- Show app branding/loading
- Wait briefly on launch
- Check whether a local session exists
- Redirect to `Home` or `Login`

### Login Screen

- Email input
- Password input
- Validation
- Login action
- Navigate to signup

### Signup Screen

- Name input
- Email input
- Password input
- Confirm password input
- Validation
- Signup action

### Home Screen

- Temporary landing screen after login/signup
- Shows current session user
- Logout action

## State Management

GetX is used for:

- Navigation
- Controller injection
- Reactive loading state
- Current user session state

## Current Session Logic

Right now auth is local/demo based:

- Login creates a local user session
- Signup creates a local user session
- Session is stored with `SharedPreferences`
- Splash reads local session and redirects

This is enough to build the first app flow before real API integration.

## Next Recommended Phase

After this, build the reusable commerce module:

1. Category model
2. Product model
3. Category list on home screen
4. Product detail screen
5. API service/repository
6. Same UI for clothes and grocery, only data changes

## Dependency Added

```yaml
get: ^4.7.2
```

