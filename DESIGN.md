# GanaderaSoft - UI/UX Overview

## 🎨 Visual Design Summary

### Color Scheme
- **Primary Green**: `#2E7D32` (Dark forest green)
- **Light Green**: `#4CAF50` (Modern vibrant green)
- **Background Light**: `#FAFAFA` (Clean white-gray)
- **Background Dark**: `#121212` (Material dark)

### App Flow

#### 1. Splash Screen
```
┌─────────────────────┐
│                     │
│     [🚜 Icon]      │
│                     │
│   GanaderaSoft     │
│ Gestión de Fincas  │
│    Ganaderas       │
│                     │
│     [Loading...]    │
│                     │
└─────────────────────┘
```

#### 2. Login Screen  
```
┌─────────────────────┐
│                     │
│     [🚜 Icon]      │
│   GanaderaSoft     │
│ Gestión de Fincas  │
│                     │
│ ┌─────────────────┐ │
│ │ Email           │ │
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │ Contraseña  👁  │ │
│ └─────────────────┘ │
│                     │
│ ┌─────────────────┐ │
│ │ Iniciar Sesión  │ │
│ └─────────────────┘ │
└─────────────────────┘
```

#### 3. Home Screen
```
┌─────────────────────┐
│ ☰ GanaderaSoft    │
├─────────────────────┤
│ ┌─────────────────┐ │
│ │ ¡Bienvenido!    │ │
│ │ Sistema integral│ │
│ │ 👤 Usuario      │ │
│ │ Propietario     │ │
│ └─────────────────┘ │
│                     │
│ Accesos Rápidos     │
│ ┌────────┬────────┐ │
│ │   👤   │   🚜   │ │
│ │Mi Cuenta│ Fincas │ │
│ │Ver perfil│Gestionar│ │
│ └────────┴────────┘ │
└─────────────────────┘
```

#### 4. Navigation Drawer
```
┌─────────────────────┐
│ ┌─────────────────┐ │
│ │   🚜 Avatar     │ │
│ │ Leonel Romero   │ │
│ │ leo@example.com │ │
│ └─────────────────┘ │
│                     │
│ 🏠 Inicio           │
│ 👤 Mi Cuenta        │
│ 🚜 Administrar      │
│    Fincas           │
│ ─────────────────── │
│ 🚪 Cerrar Sesión    │
└─────────────────────┘
```

#### 5. Profile Screen
```
┌─────────────────────┐
│ ← Mi Cuenta         │
├─────────────────────┤
│ ┌─────────────────┐ │
│ │ 👤  Leonel      │ │
│ │     Romero      │ │
│ │   Propietario   │ │
│ └─────────────────┘ │
│                     │
│ Información Personal│
│ ┌─────────────────┐ │
│ │ 📧 Email        │ │
│ │ leo@example.com │ │
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │ 👤 Tipo Usuario │ │
│ │ Propietario     │ │
│ └─────────────────┘ │
└─────────────────────┘
```

#### 6. Farms Screen
```
┌─────────────────────┐
│ ← Administrar Fincas│ 🔄
├─────────────────────┤
│ ┌─────────────────┐ │
│ │ 🚜 Finca La     │ │
│ │    Esperanza    │ │
│ │ ID: 15          │ │
│ │                 │ │
│ │ 📋 Bovinos y    │ │
│ │    Porcinos     │ │
│ │ 👤 Leonel Romero│ │
│ │ 📞 04140659739  │ │
│ │                 │ │
│ │ 📅 28/07/2025   │ │
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │ 🚜 Finca La     │ │
│ │    Romeria      │ │
│ │ ...             │ │
│ └─────────────────┘ │
└─────────────────────┘
```

## 🌙 Dark Mode Support
All screens automatically adapt to system theme preferences with:
- Dark backgrounds (#121212)
- Light green accents (#4CAF50)
- Adjusted text colors for readability
- Consistent iconography and spacing

## 📱 Responsive Features
- Adaptive layouts for different screen sizes
- Touch-friendly button sizes (minimum 48dp)
- Proper spacing and padding throughout
- Material Design 3 elevation and shadows
- Smooth animations and transitions

## ♿ Accessibility
- High contrast color ratios
- Semantic labels for screen readers
- Proper focus management
- Touch target sizes meet accessibility guidelines