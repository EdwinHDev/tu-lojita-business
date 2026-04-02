# Onboarding Feature - Guía de Configuración

## 📁 Estructura del Proyecto

El proyecto sigue **Clean Architecture** con principios **SOLID**:

```
lib/
├── core/
│   ├── di/
│   │   └── injection_container.dart    # Dependency Injection
│   └── router/
│       └── app_router.dart             # Configuración de rutas con go_router
├── features/
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── onboarding_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── onboarding_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── onboarding_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── onboarding_repository.dart
│   │   │   └── usecases/
│   │   │       └── get_onboarding_items.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── onboarding_page.dart
│   │       └── widgets/
│   │           ├── onboarding_carousel.dart
│   │           └── onboarding_slide.dart
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page.dart
└── main.dart
```

## 🎨 Imágenes Requeridas

Necesitas agregar las siguientes imágenes en la carpeta `assets/images/`:

1. **onboarding_1.png** - Imagen para "Gestiona tu negocio"
2. **onboarding_2.png** - Imagen para "Aumenta tus ventas"
3. **onboarding_3.png** - Imagen para "Reportes en tiempo real"
4. **google_logo.png** (opcional) - Logo de Google para el botón

### Recomendaciones de Imágenes:
- Tamaño recomendado: 800x600px o similar
- Formato: PNG con fondo transparente
- Estilo: Ilustraciones modernas, iconos o imágenes relacionadas con negocios

**Nota:** Si las imágenes no existen, la app mostrará placeholders con iconos automáticamente.

## 🏗️ Arquitectura Implementada

### Clean Architecture Layers:

1. **Domain Layer** (Capa de Dominio)
   - `OnboardingItem`: Entidad que representa un item del onboarding
   - `OnboardingRepository`: Interfaz del repositorio (abstracción)
   - `GetOnboardingItems`: Caso de uso para obtener items

2. **Data Layer** (Capa de Datos)
   - `OnboardingLocalDataSource`: Fuente de datos local
   - `OnboardingRepositoryImpl`: Implementación del repositorio

3. **Presentation Layer** (Capa de Presentación)
   - `OnboardingPage`: Página principal del onboarding
   - `OnboardingCarousel`: Widget del carousel con indicadores
   - `OnboardingSlide`: Widget individual de cada slide

### Principios SOLID Aplicados:

- **S** (Single Responsibility): Cada clase tiene una única responsabilidad
- **O** (Open/Closed): Abierto a extensión, cerrado a modificación
- **L** (Liskov Substitution): Las implementaciones pueden sustituir abstracciones
- **I** (Interface Segregation): Interfaces específicas y pequeñas
- **D** (Dependency Inversion): Dependencias hacia abstracciones, no implementaciones

## 🚀 Características Implementadas

✅ Carousel con 3 slides de onboarding
✅ Indicadores de página animados
✅ Botón "Iniciar con Google" (navegación a /home)
✅ Navegación con go_router
✅ Dependency Injection manual
✅ Manejo de errores en carga de imágenes
✅ Diseño responsive y moderno
✅ Material Design 3

## 📝 Cómo Ejecutar

1. Instalar dependencias:
```bash
flutter pub get
```

2. Ejecutar la aplicación:
```bash
flutter run
```

## 🔄 Navegación

- **Ruta inicial:** `/onboarding`
- **Al presionar "Iniciar con Google":** Navega a `/home`

## 🎨 Personalización

### Cambiar los textos del onboarding:

Edita `lib/features/onboarding/data/datasources/onboarding_local_datasource.dart`:

```dart
OnboardingItem(
  title: 'Tu título aquí',
  description: 'Tu descripción aquí',
  imagePath: 'assets/images/tu_imagen.png',
),
```

### Cambiar el color principal:

Edita `lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF6366F1), // Cambia este color
  primary: const Color(0xFF6366F1),
),
```

## 📦 Dependencias Utilizadas

- `go_router: ^14.6.2` - Navegación declarativa
- `carousel_slider: ^5.0.0` - Carousel de imágenes

## 🔜 Próximos Pasos

Para implementar la autenticación con Google:

1. Agregar `firebase_auth` y `google_sign_in` al pubspec.yaml
2. Configurar Firebase en el proyecto
3. Crear un caso de uso `SignInWithGoogle` en la capa de dominio
4. Implementar el repositorio de autenticación
5. Conectar el botón con el caso de uso

---

**Desarrollado con Clean Architecture y principios SOLID** 🏗️
