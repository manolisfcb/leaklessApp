# Plaid — plan de integración (diferido a v1.1)

v1 sale con **entrada manual**. Este documento es el handoff para enchufar la
sincronización bancaria automática (EE.UU./Canadá → **Plaid**) más adelante.

## Ya está listo en el código (v1)

- `transactions.source` (`manual` | `plaid` | `import`, default `manual`) y
  `transactions.external_id` — migración
  `supabase/migrations/20260704180000_transaction_source.sql`.
- Índice único parcial `uq_tx_source_external (household_id, source, external_id)`
  → **idempotencia**: reprocesar un webhook hace upsert, no duplica.
- Enum `TransactionSource` (con `isAutomatic`) + campos en el modelo `Transaction`.
- `TransactionMapper` lee/escribe ambos; cubierto por
  `test/features/transaction_mapper_test.dart`.

Es decir: una transacción de Plaid ya se puede insertar/leer **sin tocar el
modelo ni la UI**. Solo falta la tubería que las trae.

## Principio de seguridad

El teléfono **nunca** ve el `access_token` ni la secret de Plaid. Toda llamada a
Plaid vive en Edge Functions con `service_role`. Igual que la lógica sensible
actual, protegida por RLS.

## Lo que falta construir (v1.1)

### 1. Backend (Supabase)
- **Tabla `plaid_items`**: `id`, `user_id`, `household_id`, `access_token`
  (cifrado con Vault/pgsodium), `item_id`, `institution_name`, `sync_cursor`,
  `status`, timestamps. RLS que **niega** todo al cliente (solo Edge Functions).
- **Edge Function `plaid-link-token`**: crea un `link_token` para abrir Plaid
  Link (recibe el `user_id` autenticado).
- **Edge Function `plaid-exchange`**: cambia `public_token` → `access_token`,
  guarda el `plaid_items` cifrado.
- **Edge Function `plaid-webhook`** (pública, verifica firma): ante
  `SYNC_UPDATES_AVAILABLE` llama `/transactions/sync` con el cursor, y hace
  **upsert** en `transactions` con `source='plaid'`, `external_id=<transaction_id>`,
  `responsible_member_id` = dueño del item, categoría mapeada.
- Mapeo de *Personal Finance Categories* de Plaid → `categories` del hogar.

### 2. Flutter
- Paquete `plaid_flutter` (Plaid Link).
- Pantalla "Conectar banco" (en onboarding y settings), **por miembro**.
- Estado de sincronización (última actualización / reconectar item caído).
- El deep link `leakless://` ya existe → reusar para el redirect OAuth de Plaid.

### 3. Operación
- **Sandbox primero** (gratis, datos falsos) → luego solicitar acceso a
  **Production** (Plaid revisa la app; planear ~1–2 semanas).
- Claves de Plaid en secrets de Supabase (no en `.env` del cliente).
- Presupuestar costo por item/request de Production.

## Orden sugerido
`plaid_items` + RLS → `plaid-link-token` → Link en Flutter (Sandbox) →
`plaid-exchange` → `plaid-webhook` + `/transactions/sync` → mapeo de categorías →
estados de UI → Production.
