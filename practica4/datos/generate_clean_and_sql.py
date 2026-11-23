import csv
import os

input_csv = 'practica4/datos/fars_crss_sample_10.csv'
clean_csv = 'practica4/datos/clean_sample_10.csv'
output_sql = 'practica4/datos/datos_prueba.sql'

rows = []
with open(input_csv, mode='r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    for row in reader:
        # Clean 'NA' and empty values
        cleaned_row = {}
        for k, v in row.items():
            if v is None or v.strip() == '' or v.strip().upper() == 'NA':
                cleaned_row[k] = '0' if k in ['AGE', 'NUMOCCS', 'PREV', 'TRAV_SP'] else 'UNKNOWN'
            else:
                cleaned_row[k] = v.strip()
        rows.append(cleaned_row)

# Write clean_sample_10.csv
os.makedirs(os.path.dirname(clean_csv), exist_ok=True)
with open(clean_csv, mode='w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print(f"Generated {clean_csv} successfully with {len(rows)} rows.")

# Generate SQL insert statements for testing the database schema
sql_statements = []
sql_statements.append("-- ============================================================================")
sql_statements.append("-- Script SQL de Datos de Prueba (Práctica 4, Ejercicio 1.4)")
sql_statements.append("-- Inserción de 10 registros limpios derivados de FARS/CRSS sample")
sql_statements.append("-- ============================================================================")
sql_statements.append("BEGIN;\n")

# 1. CLIENTES (generate 5 clients based on unique ZIPs/counties)
clients = [
    (1, 'HEAA800101HDF', 'Juan Pérez', '84319', 'Cache', 'Av. Principal', '100', 'Centro'),
    (2, 'MARM850202DF1', 'María Rodríguez', '84321', 'Cache', 'Calle Secundaria', '204', 'Norte'),
    (3, 'GARE900303XYZ', 'Ernesto García', '33511', 'Hillsborough', 'Blvd. Los Pinos', '500', 'Florida'),
    (4, 'LOPE750404ABC', 'Patricia López', '04966', 'Franklin', 'Main St.', '12', 'Maine'),
    (5, 'HERG700505DEF', 'Guillermo Hernández', '75605', 'Gregg', 'Texas Ave.', '777', 'Sur')
]

for c in clients:
    sql_statements.append(f"INSERT INTO \"CLIENTE\" (\"ID_CLIENTE\", \"rfc\", \"nombre\", \"codigo_postal\", \"ciudad\", \"calle\", \"numero_exterior\", \"colonia\") VALUES ({c[0]}, '{c[1]}', '{c[2]}', '{c[3]}', '{c[4]}', '{c[5]}', '{c[6]}', '{c[7]}') ON CONFLICT (\"ID_CLIENTE\") DO NOTHING;")

sql_statements.append("")

# 2. POLIZAS
polizas = [
    ('POL-2020-001', 1),
    ('POL-2020-002', 2),
    ('POL-2020-003', 3),
    ('POL-2020-004', 4),
    ('POL-2020-005', 5)
]

for p in polizas:
    sql_statements.append(f"INSERT INTO \"POLIZA\" (\"NUM_POLIZA\", \"ID_CLIENTE\", \"fecha_inicio\", \"fecha_fin\", \"prima_total\") VALUES ('{p[0]}', {p[1]}, '2020-01-01 00:00:00', '2021-01-01 00:00:00', 12500.00) ON CONFLICT (\"NUM_POLIZA\") DO NOTHING;")

sql_statements.append("")

# 3. COBERTURAS
coberturas = [
    (1, 'Daños Materiales', 250000.00),
    (2, 'Responsabilidad Civil', 500000.00),
    (3, 'Gastos Médicos Ocupantes', 100000.00)
]

for cob in coberturas:
    sql_statements.append(f"INSERT INTO \"COBERTURA\" (\"ID_COBERTURA\", \"descripcion\", \"suma_asegurada_max\") VALUES ({cob[0]}, '{cob[1]}', {cob[2]}) ON CONFLICT (\"ID_COBERTURA\") DO NOTHING;")

sql_statements.append("")

# 4. TALLERES
talleres = [
    ('TALL900101ABC', 'Taller Mecánico El Águila', 'HOJALATERIA'),
    ('TALL950202XYZ', 'Servicio Automotriz Rápido', 'GENERAL'),
    ('TALL880303DEF', 'MotoServicio Especializado', 'MOTOCICLETAS')
]

for t in talleres:
    sql_statements.append(f"INSERT INTO \"TALLER\" (\"RFC_TALLER\", \"nombre\", \"especialidad\") VALUES ('{t[0]}', '{t[1]}', '{t[2]}') ON CONFLICT (\"RFC_TALLER\") DO NOTHING;")

sql_statements.append("")

# 5. REPARACIONES
reparaciones = [
    ('REP-001', 'Reparación de carrocería y pintura', 12000.00),
    ('REP-002', 'Cambio de suspensión delantera', 8500.00),
    ('REP-003', 'Alineación y balanceo', 1500.00)
]

for r in reparaciones:
    sql_statements.append(f"INSERT INTO \"REPARACION\" (\"FOLIO_REPARACION\", \"descripcion\", \"costo_estimado\") VALUES ('{r[0]}', '{r[1]}', {r[2]}) ON CONFLICT (\"FOLIO_REPARACION\") DO NOTHING;")

sql_statements.append("")

# 6. ACCIDENTES (10 accidentes basados en la muestra)
for idx, row in enumerate(rows, start=1):
    st_case = row['ST_CASE']
    hour = int(row['HOUR']) if row['HOUR'].isdigit() else 12
    if hour > 23: hour = 12
    location = f"{row.get('COUNTYNAME', 'Unknown')}, {row.get('STATENAME', 'Unknown')}"
    sql_statements.append(f"INSERT INTO \"ACCIDENTE\" (\"ID_ACCIDENTE\", \"fecha\", \"lugar\", \"descripcion_hechos\") VALUES ({idx}, '2020-02-12 {hour:02d}:00:00', '{location}', 'Accidente vial FARS case {st_case}') ON CONFLICT (\"ID_ACCIDENTE\") DO NOTHING;")

sql_statements.append("")

# 7. VEHICULOS (10 vehículos)
vehicles = [
    ('ABC-12-34', 'AUTOMOVIL', 'Toyota', 'Corolla', 2018),
    ('XYZ-56-78', 'AUTOMOVIL', 'Honda', 'Civic', 2007),
    ('DEF-90-12', 'AUTOMOVIL', 'Ford', 'Focus', 2018),
    ('GHI-34-56', 'AUTOMOVIL', 'Chevrolet', 'Cruze', 2004),
    ('JKL-78-90', 'MOTOCICLETA', 'Yamaha', 'YZF-R3', 2016),
    ('MNO-12-34', 'AUTOMOVIL', 'Nissan', 'Sentra', 2016),
    ('PQR-56-78', 'AUTOMOVIL', 'Mazda', 'Mazda3', 2005),
    ('STU-90-12', 'AUTOMOVIL', 'Volkswagen', 'Jetta', 2015),
    ('VWX-34-56', 'AUTOMOVIL', 'Hyundai', 'Elantra', 2019),
    ('YZA-78-90', 'MOTOCICLETA', 'Honda', 'CBR500R', 2020)
]

for v in vehicles:
    sql_statements.append(f"INSERT INTO \"VEHICULO\" (\"MATRICULA\", \"tipo_vehiculo\", \"marca\", \"modelo\", \"anio\") VALUES ('{v[0]}', '{v[1]}', '{v[2]}', '{v[3]}', {v[4]}) ON CONFLICT (\"MATRICULA\") DO NOTHING;")

sql_statements.append("")

# 8. AUTOMOVIL / MOTOCICLETA
for v in vehicles:
    mat = v[0]
    if v[1] == 'AUTOMOVIL':
        sql_statements.append(f"INSERT INTO \"AUTOMOVIL\" (\"MATRICULA\", \"num_puertas\", \"tipo_transmision\") VALUES ('{mat}', 4, 'AUTOMATICA') ON CONFLICT (\"MATRICULA\") DO NOTHING;")
    else:
        sql_statements.append(f"INSERT INTO \"MOTOCICLETA\" (\"MATRICULA\", \"cilindrada_cc\", \"tipo_manillar\") VALUES ('{mat}', 300, 'DEPORTIVO') ON CONFLICT (\"MATRICULA\") DO NOTHING;")

sql_statements.append("")

# 9. VEHICULO_ACCIDENTE
for idx, v in enumerate(vehicles, start=1):
    sql_statements.append(f"INSERT INTO \"VEHICULO_ACCIDENTE\" (\"MATRICULA\", \"ID_ACCIDENTE\") VALUES ('{v[0]}', {idx}) ON CONFLICT (\"MATRICULA\", \"ID_ACCIDENTE\") DO NOTHING;")

sql_statements.append("")

# 10. RECLAMACIONES y PAGOS
for idx in range(1, 11):
    pol = f"POL-2020-{(idx % 5) + 1:03d}"
    pago_id = f"PAGO-{idx:03d}"
    sql_statements.append(f"INSERT INTO \"RECLAMACION\" (\"ID_ACCIDENTE\", \"NUM_POLIZA\", \"NUM_DE_PAGO\", \"estado\") VALUES ({idx}, '{pol}', '{pago_id}', 'APROBADA') ON CONFLICT (\"ID_ACCIDENTE\", \"NUM_POLIZA\", \"NUM_DE_PAGO\") DO NOTHING;")
    sql_statements.append(f"INSERT INTO \"PAGO_RECLAMACION\" (\"ID_ACCIDENTE\", \"NUM_POLIZA\", \"NUM_DE_PAGO\", \"monto\", \"fecha_pago\") VALUES ({idx}, '{pol}', '{pago_id}', 15000.00, '2020-02-15 10:00:00');")

sql_statements.append("\nCOMMIT;")

with open(output_sql, mode='w', encoding='utf-8') as f:
    f.write('\n'.join(sql_statements))

print(f"Generated {output_sql} successfully.")
