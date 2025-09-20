## UI Changes - Sync Audit Screen

### Home Screen Quick Access (NEW)
The home screen now includes a new quick access card:

```
┌─────────────────────────────────────────────────────────────┐
│                    Accesos Rápidos                          │
├─────────────────┬─────────────────┬─────────────────────────┤
│   Mi Cuenta     │     Fincas      │   Registros Pendientes │
│   👤 person     │  🚜 agriculture │   ⚠️ sync_problem      │
├─────────────────┼─────────────────┼─────────────────────────┤
│  Datos Maestros │  Bitácora de    │                        │
│  ⚙️ settings     │  Sincronización │                        │
│                 │  🔄 sync_alt    │                        │
└─────────────────┴─────────────────┴─────────────────────────┘
```

### Sync Audit Screen (NEW)
When users tap "Bitácora de Sincronización", they see:

```
┌──────────────────────────────────────────────────────────────┐
│  ← Bitácora de Sincronización              🔄 ⋮             │
├──────────────────────────────────────────────────────────────┤
│  [Todos] [Animal] [PersonalFinca] [CambiosAnimal]           │
├──────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 📱 Test Animal Conflict              [Animal]          │  │
│  │ 🕐 15/01/2024 14:30                                    │  │
│  │ Se mantuvo la versión local (más reciente)             │  │
│  │                                                        │  │
│  │ ⚠️ Conflicto detectado                                 │  │
│  │ Local animal data is newer than server data           │  │
│  │ Resolución: Kept local data, skipped server sync      │  │
│  │                                                        │  │
│  │ [Local] 📱        [Servidor] ☁️                        │  │
│  │ 15/01/24 14:30    15/01/24 12:30                      │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ ✅ New Server Animal                 [Animal]          │  │
│  │ 🕐 15/01/2024 14:25                                    │  │
│  │ Sincronización exitosa desde el servidor              │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 📱 Juan Pérez Local               [PersonalFinca]      │  │
│  │ 🕐 15/01/2024 14:20                                    │  │
│  │ Se mantuvo la versión local (más reciente)             │  │
│  │                                                        │  │
│  │ ⚠️ Conflicto detectado                                 │  │
│  │ Local personal finca data is newer than server data   │  │
│  │ Resolución: Kept local data, skipped server sync      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Key Visual Elements:

1. **Tabbed Interface**: Users can filter by entity type (Todos, Animal, PersonalFinca, CambiosAnimal)

2. **Status Icons**: 
   - 📱 (smartphone) = Local data preserved
   - ✅ (check) = Successful sync
   - ☁️ (cloud_download) = Server data accepted
   - ⚠️ (warning) = Conflict detected

3. **Color Coding**:
   - Green: Successful operations
   - Orange: Conflicts/skipped operations  
   - Blue: Local data preserved
   - Red: Errors (if any)

4. **Conflict Details**: When conflicts occur, users see:
   - Clear description of what happened
   - Timestamps for both local and server versions
   - Resolution explanation
   - Colored containers for easy identification

5. **Actions Available**:
   - Refresh button to reload records
   - Menu with cleanup option for old records
   - Tab navigation for filtering

### User Experience Flow:

1. **User makes offline changes** → Local timestamps recorded in UTC
2. **Connection restored, sync begins** → Timestamp comparison occurs
3. **Conflicts detected** → Audit records created, local data preserved
4. **User checks "Bitácora de Sincronización"** → Sees what happened during sync
5. **User understands** → Why their changes weren't overwritten

This implementation ensures users are never surprised by lost data and have full visibility into the sync process.