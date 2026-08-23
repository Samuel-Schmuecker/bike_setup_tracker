// lib/data/bike_presets.dart

import '../models/bike.dart';
import '../models/bike_parameters.dart';

// bike_presets.dart
//
// Vorausgewählte Bike-Datenbank für die Fahrwerks-Setup-App.
// Enthält 36 Enduro-/Trail-/Downhill-Bikes bekannter Hersteller,
// jeweils in der Top-Ausstattungsvariante (dort sind i.d.R. alle
// Verstellmöglichkeiten des Fahrwerks vorhanden).
//
// WICHTIG:
// - imagePath ist überall null. Echte Herstellerfotos dürfen nicht
//   automatisch eingebettet werden (Urheberrecht) – bitte eigene
//   Bilder im Querformat unter assets/bikes/<id>.jpg ablegen und
//   imagePath entsprechend setzen, oder das Feld beim Laden der
//   Presets mit einem lokalen Pfad befüllen.
// - Federelement-Ausstattung wurde anhand der Top-Trim-Spezifikation
//   (Modelljahr 2024–2026) recherchiert. Hersteller ändern Spec und
//   Dämpfer-Generation regelmäßig – vor Produktivnutzung stichprobenartig
//   gegen die aktuelle Herstellerseite prüfen.
// - travelFront/travelRear in mm.
// ============================================================
// Wiederverwendbare Federelement-Profile
// ============================================================
// Diese Records bilden ab, welche Verstellmöglichkeiten ein
// bestimmtes Gabel- bzw. Dämpfer-Modell typischerweise bietet.
// So muss nicht jedes Bike einzeln alle 18 Bool-Felder von Hand
// pflegen – stattdessen wird pro Bike nur das passende Fork-/
// Shock-Profil referenziert.

typedef ForkProfile = ({
  bool psi,
  bool ott,
  bool hsc,
  bool lsc,
  bool hsr,
  bool lsr,
  bool tokens,
  bool hbo,
});

typedef ShockProfile = ({
  bool isCoil,
  bool psi,
  bool tokens,
  bool rate,
  bool preload,
  bool hsc,
  bool lsc,
  bool hsr,
  bool lsr,
  bool hbo,
});

// --- Gabel-Profile ---

/// Fox 36/38/40 Factory, Dämpfer GRIP2 bzw. GRIP X2 (2025+).
/// Vollständig unabhängige HSC/LSC/HSR/LSR-Verstellung, Luftdruck,
/// Volume-Spacer. Kein OTT, kein externes HBO.
const forkFoxFactoryGrip2 = (
  psi: true,
  ott: false,
  hsc: true,
  lsc: true,
  hsr: true,
  lsr: true,
  tokens: true,
  hbo: false,
);

/// RockShox ZEB/Lyrik/BoXXer Ultimate, Dämpfer Charger 3/3.1 RC2.
/// HSC + LSC unabhängig, aber nur eine (Low-Speed-)Rebound-Verstellung,
/// keine separate HSR. Luftdruck + Bottomless Tokens.
const forkRockshoxChargerRC2 = (
  psi: true,
  ott: false,
  hsc: true,
  lsc: true,
  hsr: false,
  lsr: true,
  tokens: true,
  hbo: false,
);

/// Öhlins RXF36/38 m.2. HSC + LSC, OTT (Off-The-Top-Vorspannung der
/// Luftfeder), nur eine Rebound-Verstellung, Volume-Spacer.
const forkOhlinsRXF = (
  psi: true,
  ott: true,
  hsc: true,
  lsc: true,
  hsr: false,
  lsr: true,
  tokens: true,
  hbo: false,
);

// --- Dämpfer-Profile ---

/// Fox Float X2 Factory (Luft, 4-fach: HSC/LSC/HSR/LSR unabhängig).
const shockFoxFloatX2Factory = (
  isCoil: false,
  psi: true,
  tokens: true,
  rate: false,
  preload: false,
  hsc: true,
  lsc: true,
  hsr: true,
  lsr: true,
  hbo: false,
);

/// Fox Float X Factory (Luft, einfacher: nur LSC/LSR).
const shockFoxFloatXFactory = (
  isCoil: false,
  psi: true,
  tokens: true,
  rate: false,
  preload: false,
  hsc: false,
  lsc: true,
  hsr: false,
  lsr: true,
  hbo: false,
);

/// RockShox Super Deluxe Ultimate (Luft). HSC/LSC unabhängig,
/// eine Rebound-Verstellung, Tokens.
const shockRockshoxSuperDeluxeUltimateAir = (
  isCoil: false,
  psi: true,
  tokens: true,
  rate: false,
  preload: false,
  hsc: true,
  lsc: true,
  hsr: false,
  lsr: true,
  hbo: false,
);

/// Fox DHX2 Factory (Coil). Federrate + Vorspannung, HSC/LSC/HSR/LSR
/// vollständig unabhängig, zusätzlich Hydraulic Bottom Out (HBO).
const shockFoxDHX2FactoryCoil = (
  isCoil: true,
  psi: false,
  tokens: false,
  rate: true,
  preload: true,
  hsc: true,
  lsc: true,
  hsr: true,
  lsr: true,
  hbo: true,
);

/// RockShox Super Deluxe Coil Ultimate (RC2T). Federrate + Vorspannung,
/// HSC/LSC + eine Rebound-Verstellung, plus HBO.
const shockRockshoxSuperDeluxeCoilUltimate = (
  isCoil: true,
  psi: false,
  tokens: false,
  rate: true,
  preload: true,
  hsc: true,
  lsc: true,
  hsr: false,
  lsr: true,
  hbo: true,
);

/// RockShox Vivid Coil Ultimate. Gleiches Profil wie Super Deluxe
/// Coil Ultimate (RC2T-Dämpfer mit HBO).
const shockRockshoxVividCoilUltimate = shockRockshoxSuperDeluxeCoilUltimate;

// ============================================================
// Hilfsfunktion: Fork- + Shock-Profil zu BikeParameters zusammenführen
// ============================================================

BikeParameters _params(ForkProfile fork, ShockProfile shock) => BikeParameters(
      forkPsi: fork.psi,
      forkOtt: fork.ott,
      forkHsc: fork.hsc,
      forkLsc: fork.lsc,
      forkHsr: fork.hsr,
      forkLsr: fork.lsr,
      forkTokens: fork.tokens,
      forkHbo: fork.hbo,
      shockIsCoil: shock.isCoil,
      shockPsi: shock.psi,
      shockTokens: shock.tokens,
      shockRate: shock.rate,
      shockPreload: shock.preload,
      shockHsc: shock.hsc,
      shockLsc: shock.lsc,
      shockHsr: shock.hsr,
      shockLsr: shock.lsr,
      shockHbo: shock.hbo,
    );

// ============================================================
// Bike-Presets
// ============================================================
// Reihenfolge: Enduro/Trail zuerst, dann Downhill.
// Kommentar hinter jedem Bike = tatsächlich verbaute Gabel / Dämpfer,
// als Referenz für dich bzw. für einen zukünftigen "Modell"-Info-Text.

final List<Bike> presetBikes = [
  // ---------------- Enduro / Trail ----------------
   Bike(id: 'trek_slash', brand: 'Trek', model: 'Slash 9.9 XX AXS', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'trek_fuel_ex', brand: 'Trek', model: 'Fuel EX 9.9 XTR', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
   Bike(id: 'specialized_enduro', brand: 'Specialized', model: 'Enduro Pro', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'specialized_stumpjumper_evo', brand: 'Specialized', model: 'Stumpjumper EVO Pro', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'santacruz_megatower', brand: 'Santa Cruz', model: 'Megatower CC X0 AXS', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'santacruz_nomad', brand: 'Santa Cruz', model: 'Nomad CC X0 AXS', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'yt_capra', brand: 'YT', model: 'Capra Core 4', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'yt_jeffsy', brand: 'YT', model: 'Jeffsy Core 4', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'canyon_strive', brand: 'Canyon', model: 'Strive CFR', category: 'Enduro', travelFront: 170, travelRear: 150, imagePath: null),
   Bike(id: 'canyon_torque', brand: 'Canyon', model: 'Torque CFR', category: 'Enduro', travelFront: 180, travelRear: 175, imagePath: null),
   Bike(id: 'canyon_spectral', brand: 'Canyon', model: 'Spectral CFR', category: 'Trail', travelFront: 150, travelRear: 150, imagePath: null),
   Bike(id: 'giant_reign', brand: 'Giant', model: 'Reign Advanced Pro 29', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'giant_trance_x', brand: 'Giant', model: 'Trance X Advanced Pro 29', category: 'Trail', travelFront: 150, travelRear: 135, imagePath: null),
   Bike(id: 'scott_ransom', brand: 'Scott', model: 'Ransom 900 Tuned', category: 'Enduro', travelFront: 180, travelRear: 170, imagePath: null),
   Bike(id: 'pivot_firebird', brand: 'Pivot', model: 'Firebird Pro XT/XTR', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'norco_range', brand: 'Norco', model: 'Range C1', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'commencal_meta_am', brand: 'Commencal', model: 'Meta AM 29 Team', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'propain_spindrift', brand: 'Propain', model: 'Spindrift CF', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'cube_stereo_one77', brand: 'Cube', model: 'Stereo ONE77 C:68X', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'orbea_rallon', brand: 'Orbea', model: 'Rallon M-LTD', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'transition_spire', brand: 'Transition', model: 'Spire X01 AXS', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'rockymountain_slayer', brand: 'Rocky Mountain', model: 'Slayer C70', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'nukeproof_giga', brand: 'Nukeproof', model: 'Giga 297 RS', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'ibis_hd6', brand: 'Ibis', model: 'HD6 X01 AXS', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'devinci_spartan', brand: 'Devinci', model: 'Spartan GX AXS', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'forbidden_druid', brand: 'Forbidden', model: 'Druid V2 XT', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),

  // ---------------- Downhill ----------------
   Bike(id: 'specialized_demo', brand: 'Specialized', model: 'Demo Pro', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'santacruz_v10', brand: 'Santa Cruz', model: 'V10 CC X01 DH', category: 'Downhill', travelFront: 200, travelRear: 216, imagePath: null),
   Bike(id: 'yt_tues', brand: 'YT', model: 'Tues Core 3', category: 'Downhill', travelFront: 200, travelRear: 210, imagePath: null),
   Bike(id: 'canyon_sender', brand: 'Canyon', model: 'Sender CFR', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'giant_glory', brand: 'Giant', model: 'Glory Advanced', category: 'Downhill', travelFront: 203, travelRear: 200, imagePath: null),
   Bike(id: 'scott_gambler', brand: 'Scott', model: 'Gambler 900 Tuned', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'commencal_supreme_dh', brand: 'Commencal', model: 'Supreme DH V5 World Cup', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'norco_aurum', brand: 'Norco', model: 'Aurum HSP C1', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'gt_fury', brand: 'GT', model: 'Fury Team', category: 'Downhill', travelFront: 203, travelRear: 200, imagePath: null),
   Bike(id: 'nukeproof_dissent', brand: 'Nukeproof', model: 'Dissent 297 RS', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
];

// ============================================================
// Fahrwerks-Parameter je Bike (keyed by Bike.id)
// ============================================================

final Map<String, BikeParameters> presetBikeParameters = {
  // ---------------- Enduro / Trail ----------------
  'trek_slash': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air
  'trek_fuel_ex': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'specialized_enduro': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'specialized_stumpjumper_evo': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'santacruz_megatower': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox Float X2 Factory
  'santacruz_nomad': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox Float X2 Factory
  'yt_capra': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'yt_jeffsy': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'canyon_strive': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory (Shapeshifter)
  'canyon_torque': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'canyon_spectral': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'giant_reign': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'giant_trance_x': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'scott_ransom': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'pivot_firebird': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'norco_range': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'commencal_meta_am': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'propain_spindrift': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'cube_stereo_one77': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'orbea_rallon': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'transition_spire': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'rockymountain_slayer': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'nukeproof_giga': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'ibis_hd6': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'devinci_spartan': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'forbidden_druid': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory

  // ---------------- Downhill ----------------
  'specialized_demo': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'santacruz_v10': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'yt_tues': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'canyon_sender': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'giant_glory': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'scott_gambler': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'commencal_supreme_dh': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'norco_aurum': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'gt_fury': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'nukeproof_dissent': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
};