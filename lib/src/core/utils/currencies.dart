/// Supported currencies shown in pickers, as `(code, label)` pairs.
///
/// Single source of truth so the household setup and profile screens stay in
/// sync (quality rule #13: no scattered magic lists). Codes are ISO 4217.
const supportedCurrencies = <(String, String)>[
  ('CAD', 'Dólar canadiense'),
  ('USD', 'Dólar estadounidense'),
  ('EUR', 'Euro'),
  ('MXN', 'Peso mexicano'),
  ('COP', 'Peso colombiano'),
  ('ARS', 'Peso argentino'),
  ('CLP', 'Peso chileno'),
  ('PEN', 'Sol peruano'),
  ('BRL', 'Real brasileño'),
  ('GBP', 'Libra esterlina'),
  ('JPY', 'Yen japonés'),
  ('CHF', 'Franco suizo'),
];
