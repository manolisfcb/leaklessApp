import '../l10n/app_localizations.dart';

/// Supported currency codes shown in pickers. ISO 4217.
///
/// Single source of truth so the household setup and profile screens stay in
/// sync (quality rule #13: no scattered magic lists). Display names come from
/// [currencyName] so they follow the app language.
const supportedCurrencyCodes = <String>[
  'CAD',
  'USD',
  'EUR',
  'MXN',
  'COP',
  'ARS',
  'CLP',
  'PEN',
  'BRL',
  'GBP',
  'JPY',
  'CHF',
];

/// Flag emoji for a currency [code], or empty string if it can't be derived.
///
/// ISO 4217 codes start with the issuing country's ISO 3166 alpha-2 code
/// (CAD → CA → 🇨🇦, EUR → EU → 🇪🇺), so the flag is built by mapping the
/// first two letters to Unicode regional indicator symbols.
String currencyFlag(String code) {
  if (code.length < 2) return '';
  const regionalIndicatorA = 0x1F1E6;
  const letterA = 0x41; // 'A'
  const letterZ = 0x5A; // 'Z'
  final units = code.toUpperCase().codeUnits;
  if (units[0] < letterA ||
      units[0] > letterZ ||
      units[1] < letterA ||
      units[1] > letterZ) {
    return '';
  }
  return String.fromCharCodes([
    regionalIndicatorA + (units[0] - letterA),
    regionalIndicatorA + (units[1] - letterA),
  ]);
}

/// Localized display name for a currency [code], or the raw code if unknown
/// (e.g. a household saved with a currency no longer in the list).
String currencyName(String code, AppLocalizations l10n) => switch (code) {
  'CAD' => l10n.currencyCAD,
  'USD' => l10n.currencyUSD,
  'EUR' => l10n.currencyEUR,
  'MXN' => l10n.currencyMXN,
  'COP' => l10n.currencyCOP,
  'ARS' => l10n.currencyARS,
  'CLP' => l10n.currencyCLP,
  'PEN' => l10n.currencyPEN,
  'BRL' => l10n.currencyBRL,
  'GBP' => l10n.currencyGBP,
  'JPY' => l10n.currencyJPY,
  'CHF' => l10n.currencyCHF,
  _ => code,
};
