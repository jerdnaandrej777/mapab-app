# Laravel Backend Migration

> **STATUS: GEPLANT - NICHT IMPLEMENTIERT**
>
> Dieses Dokument beschreibt eine **geplante** Migration, die noch **nicht umgesetzt** wurde.
>
> **Aktueller Backend-Stack:** Node.js/TypeScript auf Vercel + Supabase
>
> Diese Migration ist für die Zukunft geplant, hat aber keinen festen Zeitplan.

---

Diese Dokumentation beschreibt den geplanten Umstieg von Vercel + Supabase auf ein eigenes Laravel-Backend.

---

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Aktuelles vs. Neues Backend](#aktuelles-vs-neues-backend)
3. [API-Struktur](#api-struktur)
4. [Datenbank-Schema](#datenbank-schema)
5. [Migrations-Phasen](#migrations-phasen)
6. [Flutter-Änderungen](#flutter-änderungen)
7. [Kosten](#kosten)
8. [Vor- und Nachteile](#vor--und-nachteile)

---

## Übersicht

| Aspekt | Wert |
|--------|------|
| Ziel | Vercel + Supabase durch Laravel ersetzen |
| Hosting | VPS (Hetzner/Contabo) |
| Datenbank | MySQL |
| Auth | Laravel Sanctum |

---

## Aktuelles vs. Neues Backend

| Komponente | Aktuell | Geplant |
|------------|---------|---------|
| API-Proxy | Vercel (Node.js) | Laravel |
| Auth | Supabase Auth | Laravel Sanctum |
| Datenbank | Supabase PostgreSQL | MySQL |
| Rate-Limiting | In-Memory | Laravel Rate Limiter |
| Hosting | Vercel + Supabase | VPS (~4€/Monat) |
| OpenAI | Backend-Proxy | Laravel Controller |

---

## API-Struktur

### Public Routes

```
GET  /api/health                 # Health-Check
```

### AI Routes (Rate Limited)

```
POST /api/ai/chat               # AI-Chat (100 req/Tag)
POST /api/ai/trip-plan          # Trip-Generator (20 req/Tag)
```

### Auth Routes

```
POST /api/auth/register         # Registrierung
POST /api/auth/login            # Login
POST /api/auth/forgot-password  # Passwort-Reset
POST /api/auth/logout           # Logout (Auth required)
```

### Protected Routes (Sanctum)

```
GET/PATCH  /api/users/me                    # Profil
GET/POST   /api/trips                       # Trips
GET/PATCH/DELETE /api/trips/:id             # Trip-Details
POST       /api/trips/:id/complete          # Trip abschließen
GET/POST   /api/favorites/pois              # POI-Favoriten
DELETE     /api/favorites/pois/:id          # POI entfernen
GET/POST   /api/achievements                # Achievements
```

---

## Datenbank-Schema

### users

```sql
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    username VARCHAR(50) UNIQUE,
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),
    total_xp INT DEFAULT 0,
    level INT DEFAULT 1,
    total_trips_created INT DEFAULT 0,
    total_km_traveled DECIMAL(10,2) DEFAULT 0,
    total_pois_visited INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### trips

```sql
CREATE TABLE trips (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    start_lat DECIMAL(10,8) NOT NULL,
    start_lng DECIMAL(11,8) NOT NULL,
    start_address VARCHAR(500),
    end_lat DECIMAL(10,8) NOT NULL,
    end_lng DECIMAL(11,8) NOT NULL,
    end_address VARCHAR(500),
    distance_km DECIMAL(10,2),
    duration_minutes INT,
    route_geometry JSON,
    is_favorite BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### trip_stops

```sql
CREATE TABLE trip_stops (
    id CHAR(36) PRIMARY KEY,
    trip_id CHAR(36) NOT NULL,
    poi_id VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    category_id VARCHAR(50),
    stop_order INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);
```

### favorite_pois

```sql
CREATE TABLE favorite_pois (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    poi_id VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    category_id VARCHAR(50),
    image_url VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_poi (user_id, poi_id)
);
```

### user_achievements

```sql
CREATE TABLE user_achievements (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    achievement_id VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_achievement (user_id, achievement_id)
);
```

---

## Migrations-Phasen

| Phase | Beschreibung | Status |
|-------|--------------|--------|
| 1 | Laravel-Projekt Setup | Wartend |
| 2 | Datenbank-Migrationen | Wartend |
| 3 | API-Routes definieren | Wartend |
| 4 | Controller implementieren | Wartend |
| 5 | Rate-Limiting konfigurieren | Wartend |
| 6 | Flutter-App anpassen | Wartend |
| 7 | VPS-Deployment | Wartend |
| 8 | Testing & Migration | Wartend |

### Phase 1: Laravel-Projekt Setup

```bash
composer create-project laravel/laravel mapab-backend
cd mapab-backend
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

### Phase 2-4: Backend-Entwicklung

- Migrationen erstellen
- Models definieren
- API-Controller implementieren
- Request-Validation
- Rate-Limiting konfigurieren

### Phase 5: Rate-Limiting

```php
// app/Providers/RouteServiceProvider.php
RateLimiter::for('ai-chat', function (Request $request) {
    return Limit::perDay(100)->by($request->user()?->id ?: $request->ip());
});

RateLimiter::for('ai-trip-plan', function (Request $request) {
    return Limit::perDay(20)->by($request->user()?->id ?: $request->ip());
});
```

---

## Flutter-Änderungen

### Zu löschende Dateien

```
lib/core/supabase/            # Kompletter Ordner
```

### Zu ändernde Dateien

| Datei | Änderung |
|-------|----------|
| `auth_service.dart` | Laravel API statt Supabase |
| `sync_service.dart` | Laravel Endpoints |
| `auth_provider.dart` | Token-basiert statt Session |

### Neue Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0  # Für Auth-Token
  # Entfernen: supabase_flutter
```

### Auth-Interceptor für Dio

```dart
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token abgelaufen → Logout
      await _secureStorage.delete(key: 'auth_token');
      // Navigation zu Login...
    }
    handler.next(err);
  }
}
```

### Neuer Auth-Service

```dart
class LaravelAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<bool> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final token = response.data['token'];
      await _storage.write(key: 'auth_token', value: token);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _dio.post('/api/auth/logout');
    await _storage.delete(key: 'auth_token');
  }
}
```

---

## Kosten

### Monatliche Kosten

| Posten | Kosten |
|--------|--------|
| VPS (Hetzner CX21) | ~4€ |
| Domain (.de) | ~1€ |
| OpenAI API | ~5-20€ (variabel) |
| **Gesamt** | **~10-25€/Monat** |

### Vergleich mit aktueller Lösung

| Aspekt | Aktuell (Vercel + Supabase) | Laravel VPS |
|--------|----------------------------|-------------|
| Fixkosten | ~0€ (Free Tier) | ~5€ |
| Skalierung | Automatisch | Manuell |
| Kontrolle | Eingeschränkt | Voll |
| Vendor Lock-in | Ja | Nein |

---

## Vor- und Nachteile

### Vorteile

1. **Volle Kontrolle** - Eigener Server, eigene Regeln
2. **Kostentransparenz** - Fixe monatliche Kosten
3. **Kein Vendor Lock-in** - Unabhängig von Supabase
4. **PHP-Ökosystem** - Laravel Packages, einfaches Deployment
5. **Skalierbarkeit** - VPS einfach upgraden
6. **Datenschutz** - Daten auf eigenem Server in EU

### Nachteile / Risiken

1. **Server-Administration** - Eigene Wartung erforderlich
2. **Migrations-Aufwand** - Bestehende User-Daten migrieren
3. **Downtime-Risiko** - Während Migration
4. **Lernkurve** - Falls kein Laravel-Know-how vorhanden
5. **Backup-Verantwortung** - Selbst organisieren

---

## Entscheidungshilfe

**Bleibe bei Supabase wenn:**
- Free Tier ausreichend ist
- Keine spezielle Backend-Logik benötigt wird
- Server-Administration vermieden werden soll

**Migriere zu Laravel wenn:**
- Mehr Kontrolle über Daten benötigt wird
- Spezielle Backend-Logik implementiert werden soll
- Langfristige Kostenkontrolle wichtig ist
- DSGVO-Compliance auf eigenem EU-Server gewünscht ist
