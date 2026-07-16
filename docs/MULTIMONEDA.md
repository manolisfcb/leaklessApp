# Arquitectura multimoneda

La moneda original de un movimiento es la fuente de verdad. Cada transacción
guarda además un snapshot de reporte (`amount_reporting`, tasa, fecha y fuente)
para que los informes históricos no cambien cuando cambia el mercado.

## Componentes

- `accounts`: una única Cuenta principal interna por hogar. No se crean cuentas
  separadas por moneda; cada movimiento conserva su propia moneda original.
- `income_sources`: fuentes independientes de las categorías de gasto; una
  fuente puede recordar moneda y cuenta habituales.
- `exchange_rates`: cache global de tasas diarias. El cliente solo puede leer;
  `sync-exchange-rates` escribe con credenciales de backend.
- `transactions`: Cuenta principal obligatoria y snapshot CAD histórico.
- `CurrencyConverter`: conversión entera con tasa escalada a 10 decimales; no
  persiste cálculos en `double` y respeta los decimales ISO de la moneda destino.

## Semántica de lectura

- Home: saldo inicial más los snapshots CAD de todos los movimientos
  confirmados, aunque hayan sido introducidos en USD.
- Dashboard/Insights: ingresos y gastos usan exclusivamente el snapshot
  histórico. Las transferencias quedan fuera del flujo neto.
- Historial: conserva importe ISO original, fuente y snapshot CAD.

## Operación de tasas

La Edge Function consulta una vez al día `FXUSDCAD` en Bank of Canada Valet,
valida fecha/valor, impide observaciones regresivas y hace un `upsert`
idempotente. En Supabase alojado, programarla después de las 17:00 ET con Cron
(`pg_cron` + `pg_net`) y guardar URL/secret key en Vault. El endpoint exige la
secret key en `apikey`; nunca se llama desde Flutter.

Ejemplo de horario (21:15 UTC, adecuado durante EDT):

```sql
select cron.schedule(
  'sync-cad-exchange-rates',
  '15 21 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets
            where name = 'project_url') || '/functions/v1/sync-exchange-rates',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', (select decrypted_secret from vault.decrypted_secrets
                 where name = 'secret_key')
    ),
    body := '{}'::jsonb
  );
  $$
);
```

Para mantener una hora local exacta durante el cambio EDT/EST se debe ajustar
el horario UTC o usar dos jobs estacionales administrados desde operaciones.

## Verificación

```bash
supabase db reset
supabase test db supabase/tests/database/multicurrency_finance.test.sql
supabase db lint --local --level warning
flutter analyze
flutter test
```
