# Documentación de Control de Acceso y Gestión de Permisos — Sistema de Seguros de Auto (Práctica 4, Ejercicio 1.6)

Este documento detalla la arquitectura de seguridad basada en roles (RBAC) implementada para el **Sistema de Seguros de Auto** en PostgreSQL, aplicando estrictamente el **Principio de Menor Privilegio**.

---

## 1. Definición de Roles del Sistema

Se han definido tres roles operativos en la base de datos:

1. **`admin_seguros` (Administrador)**:
   - *Propósito*: Gestión total del esquema, mantenimiento de catálogos, creación de objetos DDL y control de privilegios.
   - *Privilegios*: `ALL PRIVILEGES` sobre la base de datos y todas las tablas del esquema.

2. **`app_seguros` (Aplicación Transaccional / Operador)**:
   - *Propósito*: Utilizado por el backend de la aplicación y operadores de atención para el registro de clientes, emisión de pólizas, reporte de accidentes y procesamiento de reclamaciones y pagos.
   - *Privilegios*: Permisos de lectura y escritura (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) únicamente sobre las tablas transaccionales y catálogos operativos. Sin privilegios DDL (`DROP`, `ALTER`).

3. **`consulta_seguros` (Auditoría / Reportes Gerenciales)**:
   - *Propósito*: Utilizado por analistas de datos, gerencia y sistemas de BI para la generación de reportes, consultas analíticas y auditorías financieras.
   - *Privilegios*: Acceso exclusivo de lectura (`SELECT`) en todo el esquema transaccional, con prohibición absoluta de modificar o insertar datos.

---

## 2. Matriz de Permisos (Rol vs. Tabla vs. Privilegios)

| Tabla / Vista | `admin_seguros` | `app_seguros` | `consulta_seguros` |
| :--- | :--- | :--- | :--- |
| `CLIENTE` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `CLIENTE_TELEFONO` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `POLIZA` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `COBERTURA` | ALL | SELECT, INSERT, UPDATE | SELECT |
| `POLIZA_COBERTURA` | ALL | SELECT, INSERT, DELETE | SELECT |
| `ACCIDENTE` | ALL | SELECT, INSERT, UPDATE | SELECT |
| `VEHICULO` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `VEHICULO_ACCIDENTE`| ALL | SELECT, INSERT, DELETE | SELECT |
| `AUTOMOVIL` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `MOTOCICLETA` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `TALLER` | ALL | SELECT, INSERT, UPDATE | SELECT |
| `REPARACION` | ALL | SELECT, INSERT, UPDATE | SELECT |
| `REPARA` | ALL | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `RECLAMACION` | ALL | SELECT, INSERT, UPDATE | SELECT |
| `PAGO_RECLAMACION` | ALL | SELECT, INSERT, UPDATE | SELECT |

---

## 3. Configuración y Buenas Prácticas de Contraseñas

Las credenciales y contraseñas de acceso **nunca se almacenan en texto plano en los scripts SQL versionados**. Se configuran mediante variables de entorno en el sistema operativo o archivos de conexión seguros (`.pgpass`):

```bash
# Ejemplo de configuración segura en entorno de ejecución:
export PGPASSWORD_ADMIN='AdminSeguros#2026_SecureKey!'
export PGPASSWORD_APP='AppSeguros#2026_TransactKey!'
export PGPASSWORD_CONSULTA='ConsultaSeguros#2026_ReadonlyKey!'
```

---

## 4. Pruebas de Permisos y Mensajes de Error (Casos de Éxito y Denegación)

### Prueba 1: Conexión y Operación Permitida con `app_seguros`
- **Conexión**:
  ```bash
  psql -U app_seguros -d seguros_db -h localhost
  ```
- **Operación Ejecutada**:
  ```sql
  INSERT INTO "CLIENTE" ("ID_CLIENTE", "rfc", "nombre", "codigo_postal", "ciudad", "calle", "numero_exterior", "colonia")
  VALUES (201, 'GUIM850101XYZ', 'María Gutiérrez', '44100', 'Guadalajara', 'Juárez', '505', 'Centro');
  ```
- **Resultado Real**: `INSERT 0 1` (Operación exitosa por tener privilegio `INSERT`).

---

### Prueba 2: Operación Prohibida (Escritura) con `consulta_seguros`
- **Conexión**:
  ```bash
  psql -U consulta_seguros -d seguros_db -h localhost
  ```
- **Operación Ejecutada**:
  ```sql
  DELETE FROM "CLIENTE" WHERE "ID_CLIENTE" = 201;
  ```
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: permission denied for table CLIENTE
  ```
- **Regla Protegida**: Principio de menor privilegio (el rol de consulta no puede alterar registros).

---

### Prueba 3: Demostración de `REVOKE` (Denegación Inmediata)
- **Ejecución por Administrador**:
  ```sql
  REVOKE INSERT, UPDATE, DELETE ON "CLIENTE" FROM app_seguros;
  ```
- **Intento posterior con `app_seguros`**:
  ```sql
  INSERT INTO "CLIENTE" ("ID_CLIENTE", "rfc", "nombre", "codigo_postal", "ciudad", "calle", "numero_exterior", "colonia")
  VALUES (202, 'PEPJ800101ABC', 'Pedro Pérez', '01000', 'CDMX', 'Insurgentes', '12', 'Del Valle');
  ```
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: permission denied for table CLIENTE
  ```
- **Regla Protegida**: Revocación dinámica y efectiva de privilegios en tiempo de ejecución.
