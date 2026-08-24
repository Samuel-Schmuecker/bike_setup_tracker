// lib/data/bike_presets.dart

import '../models/bike.dart';
import '../models/bike_parameters.dart';


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
// Neue Fahrwerks-Profile (Cross Country)
// ============================================================
 
/// Fox 32/34 SC Factory, GRIP-Dämpfer (Lockout/Open + eine
/// Compression-Stufe). Kein HSC/HSR, nur LSC/LSR.
const forkFoxFactorySL = (
  psi: true,
  ott: false,
  hsc: false,
  lsc: true,
  hsr: false,
  lsr: true,
  tokens: true,
  hbo: false,
);
 
/// RockShox SID Ultimate, Charger Race Day Dämpfer. Analoges Profil:
/// Lockout/Open + eine Compression-Stufe, keine HSC/HSR-Trennung.
const forkRockshoxSIDUltimate = (
  psi: true,
  ott: false,
  hsc: false,
  lsc: true,
  hsr: false,
  lsr: true,
  tokens: true,
  hbo: false,
);
 
/// Fox Float SL Factory (XC-Luftdämpfer). Lockout + eine
/// Compression-/Rebound-Stufe.
const shockFoxFloatSLFactory = (
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
 
/// RockShox SIDLuxe Ultimate. Analoges Profil zum Fox Float SL.
const shockRockshoxSIDLuxeUltimate = (
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

   // Erweiterung 1
   // ---------------- Weitere Modelle bereits vorhandener Marken ----------------
   Bike(id: 'trek_session', brand: 'Trek', model: 'Session 9', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'trek_remedy', brand: 'Trek', model: 'Remedy 9.9', category: 'Enduro', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'specialized_status', brand: 'Specialized', model: 'Status 160', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'santacruz_bronson', brand: 'Santa Cruz', model: 'Bronson CC X0 AXS', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'santacruz_hightower', brand: 'Santa Cruz', model: 'Hightower CC X0 AXS', category: 'Trail', travelFront: 150, travelRear: 145, imagePath: null),
   Bike(id: 'commencal_meta_sx', brand: 'Commencal', model: 'Meta SX', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'propain_tyee', brand: 'Propain', model: 'Tyee CF', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'cube_two15', brand: 'Cube', model: 'Two15 C:68X SL', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'orbea_occam', brand: 'Orbea', model: 'Occam M-LTD', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
   Bike(id: 'transition_patrol', brand: 'Transition', model: 'Patrol X01 AXS', category: 'Enduro', travelFront: 160, travelRear: 160, imagePath: null),
   Bike(id: 'transition_sentinel', brand: 'Transition', model: 'Sentinel X01 AXS', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'rockymountain_altitude', brand: 'Rocky Mountain', model: 'Altitude C70', category: 'Enduro', travelFront: 160, travelRear: 160, imagePath: null),
   Bike(id: 'nukeproof_mega', brand: 'Nukeproof', model: 'Mega 297/290 RS', category: 'Enduro', travelFront: 165, travelRear: 165, imagePath: null),
   Bike(id: 'norco_sight', brand: 'Norco', model: 'Sight C1', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
   Bike(id: 'gt_sensor', brand: 'GT', model: 'Sensor Carbon Pro', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
   Bike(id: 'ibis_ripmo', brand: 'Ibis', model: 'Ripmo V2 X01', category: 'Trail', travelFront: 160, travelRear: 147, imagePath: null),
   Bike(id: 'devinci_troy', brand: 'Devinci', model: 'Troy GX AXS', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
   Bike(id: 'forbidden_dreadnought', brand: 'Forbidden', model: 'Dreadnought XT', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'mondraker_dune', brand: 'Mondraker', model: 'Dune Carbon RR', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
 
  // ---------------- Neue Marken ----------------
   Bike(id: 'cannondale_jekyll', brand: 'Cannondale', model: 'Jekyll 1', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'cannondale_habit', brand: 'Cannondale', model: 'Habit 1', category: 'Trail', travelFront: 130, travelRear: 120, imagePath: null),
   Bike(id: 'merida_one_sixty', brand: 'Merida', model: 'One-Sixty 10K', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'merida_one_forty', brand: 'Merida', model: 'One-Forty 10K', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
   Bike(id: 'radon_swoop', brand: 'Radon', model: 'Swoop 10.0', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'radon_jealous', brand: 'Radon', model: 'Jealous 10.0', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
   Bike(id: 'vitus_sommet', brand: 'Vitus', model: 'Sommet 29 CRX', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'marin_alpine_trail', brand: 'Marin', model: 'Alpine Trail XR', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
   Bike(id: 'kona_process_153', brand: 'Kona', model: 'Process 153 CR/DL', category: 'Trail', travelFront: 160, travelRear: 153, imagePath: null),
   Bike(id: 'kona_operator', brand: 'Kona', model: 'Operator CR/DL', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
   Bike(id: 'intense_tracer', brand: 'Intense', model: 'Tracer 279 Pro', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'intense_m1', brand: 'Intense', model: 'M1', category: 'Downhill', travelFront: 200, travelRear: 216, imagePath: null),
   Bike(id: 'evil_wreckoning', brand: 'Evil', model: 'Wreckoning LB', category: 'Enduro', travelFront: 160, travelRear: 158, imagePath: null),
   Bike(id: 'evil_insurgent', brand: 'Evil', model: 'Insurgent', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'privateer_141', brand: 'Privateer', model: '141', category: 'Trail', travelFront: 160, travelRear: 141, imagePath: null),
   Bike(id: 'starling_murmur', brand: 'Starling', model: 'Murmur', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'deviate_highlander', brand: 'Deviate', model: 'Highlander V3', category: 'Trail', travelFront: 160, travelRear: 155, imagePath: null),
   Bike(id: 'cotic_flaremax', brand: 'Cotic', model: 'FlareMAX Gen4', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
   Bike(id: 'antidote_lifeline', brand: 'Antidote', model: 'Lifeline', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'whyte_g170', brand: 'Whyte', model: 'G-170 RS', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'lapierre_spicy', brand: 'Lapierre', model: 'Spicy CF', category: 'Enduro', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'ghost_riot_am', brand: 'Ghost', model: 'Riot AM', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'focus_jam2', brand: 'Focus', model: 'Jam² SL', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
   Bike(id: 'liteville_301', brand: 'Liteville', model: '301 MK16', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'alutech_fanes', brand: 'Alutech', model: 'Fanes', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'simplon_rapcon', brand: 'Simplon', model: 'Rapcon Pmax', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),

// ---------------- All Mountain ----------------
   Bike(id: 'specialized_stumpjumper', brand: 'Specialized', model: 'Stumpjumper Pro', category: 'All Mountain', travelFront: 150, travelRear: 145, imagePath: null),
   Bike(id: 'yeti_sb140', brand: 'Yeti', model: 'SB140', category: 'All Mountain', travelFront: 140, travelRear: 140, imagePath: null),
   Bike(id: 'pivot_trail429', brand: 'Pivot', model: 'Trail 429 Pro XT/XTR', category: 'All Mountain', travelFront: 130, travelRear: 125, imagePath: null),
   Bike(id: 'banshee_prime', brand: 'Banshee', model: 'Prime', category: 'All Mountain', travelFront: 140, travelRear: 140, imagePath: null),
   Bike(id: 'knolly_fugitive', brand: 'Knolly', model: 'Fugitive LT', category: 'All Mountain', travelFront: 160, travelRear: 155, imagePath: null),
   Bike(id: 'guerrillagravity_trailpistol', brand: 'Guerrilla Gravity', model: 'Trail Pistol', category: 'All Mountain', travelFront: 140, travelRear: 135, imagePath: null),
 
  // ---------------- Cross Country ----------------
   Bike(id: 'specialized_epic', brand: 'Specialized', model: 'Epic 8', category: 'Cross Country', travelFront: 120, travelRear: 110, imagePath: null),
   Bike(id: 'trek_supercaliber', brand: 'Trek', model: 'Supercaliber SLR', category: 'Cross Country', travelFront: 100, travelRear: 60, imagePath: null),
   Bike(id: 'cannondale_scalpel', brand: 'Cannondale', model: 'Scalpel Hi-MOD', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
   Bike(id: 'santacruz_blur', brand: 'Santa Cruz', model: 'Blur TR', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
   Bike(id: 'scott_spark', brand: 'Scott', model: 'Spark RC Ultimate', category: 'Cross Country', travelFront: 120, travelRear: 120, imagePath: null),
   Bike(id: 'giant_anthem', brand: 'Giant', model: 'Anthem Advanced Pro 29', category: 'Cross Country', travelFront: 110, travelRear: 105, imagePath: null),
 
  // ---------------- E-Bike ----------------
   Bike(id: 'specialized_kenevo_sl', brand: 'Specialized', model: 'Kenevo SL Expert', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'specialized_levo', brand: 'Specialized', model: 'Turbo Levo 4 Expert', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'trek_rail', brand: 'Trek', model: 'Rail 9.9 XX AXS', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
   Bike(id: 'canyon_spectral_on', brand: 'Canyon', model: 'Spectral:ON CFR', category: 'E-Bike', travelFront: 150, travelRear: 150, imagePath: null),
   Bike(id: 'giant_reign_e', brand: 'Giant', model: 'Reign E+ Elite', category: 'E-Bike', travelFront: 160, travelRear: 155, imagePath: null),
   Bike(id: 'yt_decoy', brand: 'YT', model: 'Decoy Core 4', category: 'E-Bike', travelFront: 170, travelRear: 165, imagePath: null),
   Bike(id: 'orbea_wild', brand: 'Orbea', model: 'Wild M-LTD', category: 'E-Bike', travelFront: 170, travelRear: 160, imagePath: null),
   Bike(id: 'norco_sight_vlt', brand: 'Norco', model: 'Sight VLT C1', category: 'E-Bike', travelFront: 150, travelRear: 140, imagePath: null),

   // 3. Erweiterung
  
  // ================= Enduro (22) =================
  Bike(id: 'yeti_sb165', brand: 'Yeti', model: 'SB165', category: 'Enduro', travelFront: 165, travelRear: 160, imagePath: null),
  Bike(id: 'yeti_sb160', brand: 'Yeti', model: 'SB160', category: 'Enduro', travelFront: 160, travelRear: 160, imagePath: null),
  Bike(id: 'gt_force', brand: 'GT', model: 'Force Carbon Pro', category: 'Enduro', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'norco_range_2022', brand: 'Norco', model: 'Range C2 (2022)', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
  Bike(id: 'specialized_enduro_2021', brand: 'Specialized', model: 'S-Works Enduro 29 (2021)', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
  Bike(id: 'santacruz_megatower_2020', brand: 'Santa Cruz', model: 'Megatower CC (2020)', category: 'Enduro', travelFront: 160, travelRear: 160, imagePath: null),
  Bike(id: 'trek_slash_2023', brand: 'Trek', model: 'Slash 9.9 Gen 5 (2023)', category: 'Enduro', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'canyon_strive_2022', brand: 'Canyon', model: 'Strive CFR (2022)', category: 'Enduro', travelFront: 170, travelRear: 150, imagePath: null),
  Bike(id: 'commencal_meta_am_2023', brand: 'Commencal', model: 'Meta AM 29 (2023)', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
  Bike(id: 'nicolai_g1', brand: 'Nicolai', model: 'G1', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
  Bike(id: 'nicolai_saturn14', brand: 'Nicolai', model: 'Saturn14', category: 'Enduro', travelFront: 165, travelRear: 160, imagePath: null),
  Bike(id: 'last_tarvis', brand: 'Last', model: 'Tarvis', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
  Bike(id: 'polygon_collosus_n9', brand: 'Polygon', model: 'Collosus N9', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
  Bike(id: 'norco_shore', brand: 'Norco', model: 'Shore', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
  Bike(id: 'canfield_jedi', brand: 'Canfield', model: 'Jedi', category: 'Enduro', travelFront: 165, travelRear: 160, imagePath: null),
  Bike(id: 'geometron_g16', brand: 'Geometron', model: 'G16', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
  Bike(id: 'pole_evolink', brand: 'POLE', model: 'Evolink 176', category: 'Enduro', travelFront: 176, travelRear: 170, imagePath: null),
  Bike(id: 'stanton_slackline', brand: 'Stanton', model: 'Slackline', category: 'Enduro', travelFront: 160, travelRear: 160, imagePath: null),
  Bike(id: 'saracen_kiliflyer', brand: 'Saracen', model: 'Kili Flyer', category: 'Enduro', travelFront: 170, travelRear: 165, imagePath: null),
  Bike(id: 'yt_capra_2022', brand: 'YT', model: 'Capra (2022)', category: 'Enduro', travelFront: 170, travelRear: 170, imagePath: null),
  Bike(id: 'propain_hugene', brand: 'Propain', model: 'Hugene', category: 'Enduro', travelFront: 165, travelRear: 160, imagePath: null),
  Bike(id: 'giant_reign_2023', brand: 'Giant', model: 'Reign Advanced (2023)', category: 'Enduro', travelFront: 160, travelRear: 146, imagePath: null),

  // ================= Trail (22) =================
  Bike(id: 'rockymountain_instinct', brand: 'Rocky Mountain', model: 'Instinct C70', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'vitus_escarpe', brand: 'Vitus', model: 'Escarpe 29 CRX', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'santacruz_5010', brand: 'Santa Cruz', model: '5010 CC X0 AXS', category: 'Trail', travelFront: 130, travelRear: 130, imagePath: null),
  Bike(id: 'santacruz_tallboy', brand: 'Santa Cruz', model: 'Tallboy CC X0 AXS', category: 'Trail', travelFront: 130, travelRear: 120, imagePath: null),
  Bike(id: 'pivot_switchblade', brand: 'Pivot', model: 'Switchblade Pro XT/XTR', category: 'Trail', travelFront: 160, travelRear: 142, imagePath: null),
  Bike(id: 'transition_scout', brand: 'Transition', model: 'Scout X01 AXS', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
  Bike(id: 'norco_optic', brand: 'Norco', model: 'Optic C1', category: 'Trail', travelFront: 130, travelRear: 120, imagePath: null),
  Bike(id: 'norco_fluid', brand: 'Norco', model: 'Fluid FS C1', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
  Bike(id: 'marin_rift_zone', brand: 'Marin', model: 'Rift Zone XR', category: 'Trail', travelFront: 130, travelRear: 125, imagePath: null),
  Bike(id: 'marin_wolf_ridge', brand: 'Marin', model: 'Wolf Ridge XR', category: 'Trail', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'radon_skeen', brand: 'Radon', model: 'Skeen Trail 10.0', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'merida_ninety_six', brand: 'Merida', model: 'Ninety-Six 10K', category: 'Trail', travelFront: 120, travelRear: 100, imagePath: null),
  Bike(id: 'commencal_meta_tr', brand: 'Commencal', model: 'Meta TR 29', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'cube_stereo_150', brand: 'Cube', model: 'Stereo 150 C:68X', category: 'Trail', travelFront: 150, travelRear: 150, imagePath: null),
  Bike(id: 'scott_genius', brand: 'Scott', model: 'Genius ST Tuned', category: 'Trail', travelFront: 150, travelRear: 150, imagePath: null),
  Bike(id: 'polygon_siskiu', brand: 'Polygon', model: 'Siskiu T8', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'whyte_t130', brand: 'Whyte', model: 'T-130 RS', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
  Bike(id: 'lapierre_zesty', brand: 'Lapierre', model: 'Zesty AM', category: 'Trail', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'ghost_kato', brand: 'Ghost', model: 'Kato FS', category: 'Trail', travelFront: 140, travelRear: 130, imagePath: null),
  Bike(id: 'bold_linkin', brand: 'Bold', model: 'Linkin', category: 'Trail', travelFront: 150, travelRear: 145, imagePath: null),
  Bike(id: 'propain_yuma', brand: 'Propain', model: 'Yuma', category: 'Trail', travelFront: 130, travelRear: 125, imagePath: null),
  Bike(id: 'liteville_601', brand: 'Liteville', model: '601 MK6', category: 'Trail', travelFront: 155, travelRear: 150, imagePath: null),

  // ================= Downhill (12) =================
  Bike(id: 'santacruz_v10_2019', brand: 'Santa Cruz', model: 'V10 CC (2019)', category: 'Downhill', travelFront: 200, travelRear: 216, imagePath: null),
  Bike(id: 'specialized_demo_2016', brand: 'Specialized', model: 'Demo 8 (2016)', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'propain_rage', brand: 'Propain', model: 'Rage', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'intense_m279', brand: 'Intense', model: 'M279', category: 'Downhill', travelFront: 200, travelRear: 210, imagePath: null),
  Bike(id: 'foes_mixer', brand: 'Foes', model: 'Mixer', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'last_herb', brand: 'Last', model: 'Herb', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'nicolai_ion16', brand: 'Nicolai', model: 'Ion16', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'polygon_collosus_dh', brand: 'Polygon', model: 'Collosus DH9', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'trek_session_2022', brand: 'Trek', model: 'Session 9 (2022)', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'yt_tues_2021', brand: 'YT', model: 'Tues CF (2021)', category: 'Downhill', travelFront: 200, travelRear: 210, imagePath: null),
  Bike(id: 'commencal_supreme_dh_2020', brand: 'Commencal', model: 'Supreme DH V4.2 (2020)', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),
  Bike(id: 'devinci_wilson_2023', brand: 'Devinci', model: 'Wilson Carbon (2023)', category: 'Downhill', travelFront: 200, travelRear: 200, imagePath: null),

  // ================= All Mountain (14) =================
  Bike(id: 'transition_spire_alloy', brand: 'Transition', model: 'Spire Alloy GX', category: 'All Mountain', travelFront: 170, travelRear: 170, imagePath: null),
  Bike(id: 'specialized_stumpjumper_alloy', brand: 'Specialized', model: 'Stumpjumper Alloy', category: 'All Mountain', travelFront: 150, travelRear: 145, imagePath: null),
  Bike(id: 'ibis_ripley', brand: 'Ibis', model: 'Ripley V4S', category: 'All Mountain', travelFront: 120, travelRear: 120, imagePath: null),
  Bike(id: 'rockymountain_pipeline', brand: 'Rocky Mountain', model: 'Pipeline C50', category: 'All Mountain', travelFront: 150, travelRear: 150, imagePath: null),
  Bike(id: 'kona_heihei', brand: 'Kona', model: 'Hei Hei CR/DL', category: 'All Mountain', travelFront: 130, travelRear: 120, imagePath: null),
  Bike(id: 'evil_following', brand: 'Evil', model: 'Following MB', category: 'All Mountain', travelFront: 130, travelRear: 120, imagePath: null),
  Bike(id: 'privateer_161', brand: 'Privateer', model: '161', category: 'All Mountain', travelFront: 170, travelRear: 161, imagePath: null),
  Bike(id: 'deviate_claymore', brand: 'Deviate', model: 'Claymore', category: 'All Mountain', travelFront: 165, travelRear: 160, imagePath: null),
  Bike(id: 'cotic_rocketmax', brand: 'Cotic', model: 'RocketMAX', category: 'All Mountain', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'antidote_darkmatter', brand: 'Antidote', model: 'Darkmatter', category: 'All Mountain', travelFront: 150, travelRear: 145, imagePath: null),
  Bike(id: 'banshee_titan', brand: 'Banshee', model: 'Titan', category: 'All Mountain', travelFront: 160, travelRear: 160, imagePath: null),
  Bike(id: 'knolly_chilcotin', brand: 'Knolly', model: 'Chilcotin 159', category: 'All Mountain', travelFront: 170, travelRear: 159, imagePath: null),
  Bike(id: 'guerrillagravity_smash', brand: 'Guerrilla Gravity', model: 'Smash', category: 'All Mountain', travelFront: 165, travelRear: 160, imagePath: null),
  Bike(id: 'yeti_sb130', brand: 'Yeti', model: 'SB130', category: 'All Mountain', travelFront: 130, travelRear: 130, imagePath: null),

  // ================= Cross Country (16) =================
  Bike(id: 'trek_top_fuel', brand: 'Trek', model: 'Top Fuel 9.9', category: 'Cross Country', travelFront: 110, travelRear: 110, imagePath: null),
  Bike(id: 'specialized_epic_evo', brand: 'Specialized', model: 'Epic Evo Pro', category: 'Cross Country', travelFront: 130, travelRear: 120, imagePath: null),
  Bike(id: 'canyon_lux', brand: 'Canyon', model: 'Lux CFR', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
  Bike(id: 'yt_izzo', brand: 'YT', model: 'Izzo Core 4', category: 'Cross Country', travelFront: 120, travelRear: 120, imagePath: null),
  Bike(id: 'orbea_oiz', brand: 'Orbea', model: 'Oiz M-LTD', category: 'Cross Country', travelFront: 110, travelRear: 110, imagePath: null),
  Bike(id: 'pivot_mach4sl', brand: 'Pivot', model: 'Mach 4 SL Pro XT/XTR', category: 'Cross Country', travelFront: 115, travelRear: 100, imagePath: null),
  Bike(id: 'bmc_fourstroke', brand: 'BMC', model: 'Fourstroke 01', category: 'Cross Country', travelFront: 120, travelRear: 120, imagePath: null),
  Bike(id: 'vitus_sentier', brand: 'Vitus', model: 'Sentier 29', category: 'Cross Country', travelFront: 120, travelRear: 120, imagePath: null),
  Bike(id: 'stevens_jura', brand: 'Stevens', model: 'Jura', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
  Bike(id: 'simplon_kamerad', brand: 'Simplon', model: 'Kamerad Pmax', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
  Bike(id: 'ghost_lector', brand: 'Ghost', model: 'Lector FS SF', category: 'Cross Country', travelFront: 120, travelRear: 115, imagePath: null),
  Bike(id: 'norco_revolver', brand: 'Norco', model: 'Revolver FS C1', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
  Bike(id: 'rockymountain_element', brand: 'Rocky Mountain', model: 'Element C70', category: 'Cross Country', travelFront: 120, travelRear: 120, imagePath: null),
  Bike(id: 'intense_sniper', brand: 'Intense', model: 'Sniper XC Pro', category: 'Cross Country', travelFront: 110, travelRear: 100, imagePath: null),
  Bike(id: 'cube_ams_100', brand: 'Cube', model: 'AMS 100 C:68X SLT', category: 'Cross Country', travelFront: 100, travelRear: 100, imagePath: null),
  Bike(id: 'scott_spark_2021', brand: 'Scott', model: 'Spark RC (2021)', category: 'Cross Country', travelFront: 120, travelRear: 120, imagePath: null),

  // ================= E-Bike (14) =================
  Bike(id: 'trek_fuel_exe', brand: 'Trek', model: 'Fuel EXe 9.9', category: 'E-Bike', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'specialized_kenevo', brand: 'Specialized', model: 'Turbo Kenevo Expert', category: 'E-Bike', travelFront: 180, travelRear: 170, imagePath: null),
  Bike(id: 'cannondale_moterra', brand: 'Cannondale', model: 'Moterra SL 1', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'transition_relay', brand: 'Transition', model: 'Relay X01 AXS', category: 'E-Bike', travelFront: 150, travelRear: 140, imagePath: null),
  Bike(id: 'pivot_shuttle_am', brand: 'Pivot', model: 'Shuttle AM Pro XT/XTR', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'merida_eonesixty', brand: 'Merida', model: 'eOne-Sixty 10K', category: 'E-Bike', travelFront: 170, travelRear: 160, imagePath: null),
  Bike(id: 'whyte_e180', brand: 'Whyte', model: 'E-180 RSX', category: 'E-Bike', travelFront: 180, travelRear: 170, imagePath: null),
  Bike(id: 'lapierre_overvolt', brand: 'Lapierre', model: 'Overvolt AM', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'ghost_hybride_riot', brand: 'Ghost', model: 'Hybride Riot AM', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'focus_thron', brand: 'Focus', model: 'Thron² SL', category: 'E-Bike', travelFront: 160, travelRear: 150, imagePath: null),
  Bike(id: 'norco_range_vlt', brand: 'Norco', model: 'Range VLT C1', category: 'E-Bike', travelFront: 170, travelRear: 170, imagePath: null),
  Bike(id: 'canyon_neuron_on', brand: 'Canyon', model: 'Neuron:ON CF', category: 'E-Bike', travelFront: 140, travelRear: 130, imagePath: null),
  Bike(id: 'rockymountain_altitude_powerplay', brand: 'Rocky Mountain', model: 'Altitude Powerplay C70', category: 'E-Bike', travelFront: 160, travelRear: 160, imagePath: null),
  Bike(id: 'kona_remote', brand: 'Kona', model: 'Remote CTRL', category: 'E-Bike', travelFront: 150, travelRear: 140, imagePath: null),
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

  // Erweiterung 1
  // ---------------- Weitere Modelle bereits vorhandener Marken ----------------
  'trek_session': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'trek_remedy': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'specialized_status': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'santacruz_bronson': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'santacruz_hightower': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'commencal_meta_sx': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'propain_tyee': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'cube_two15': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'orbea_occam': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34/36 Factory GRIP2 / Fox Float X Factory
  'transition_patrol': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'transition_sentinel': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'rockymountain_altitude': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'nukeproof_mega': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB/Lyrik Ultimate / Super Deluxe Coil Ultimate
  'norco_sight': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'gt_sensor': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34/36 Factory GRIP2 / Fox Float X Factory
  'ibis_ripmo': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'devinci_troy': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'forbidden_dreadnought': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'mondraker_dune': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
 
  // ---------------- Neue Marken ----------------
  'cannondale_jekyll': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'cannondale_habit': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike/Lyrik Ultimate / Super Deluxe Ultimate Air
  'merida_one_sixty': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'merida_one_forty': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'radon_swoop': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'radon_jealous': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'vitus_sommet': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'marin_alpine_trail': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'kona_process_153': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'kona_operator': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'intense_tracer': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'intense_m1': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'evil_wreckoning': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36/38 Factory GRIP2 / Fox X2 Factory
  'evil_insurgent': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'privateer_141': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'starling_murmur': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory (handbuilt, individuelle Spec)
  'deviate_highlander': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'cotic_flaremax': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike/Lyrik Ultimate / Super Deluxe Ultimate Air
  'antidote_lifeline': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'whyte_g170': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'lapierre_spicy': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'ghost_riot_am': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'focus_jam2': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'liteville_301': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'alutech_fanes': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'simplon_rapcon': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory

  // ---------------- All Mountain ----------------
  'specialized_stumpjumper': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34 Factory GRIP2 / Fox Float X Factory
  'yeti_sb140': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'pivot_trail429': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34/36 Factory GRIP2 / Fox Float X Factory
  'banshee_prime': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'knolly_fugitive': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'guerrillagravity_trailpistol': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
 
  // ---------------- Cross Country ----------------
  'specialized_epic': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / Fox Float SL Factory
  'trek_supercaliber': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / IsoStrut (vereinfachtes XC-Profil, IsoStrut hat keine klassischen externen Clicker)
  'cannondale_scalpel': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'santacruz_blur': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / Fox Float SL Factory
  'scott_spark': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory (Twinloc)
  'giant_anthem': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
 
  // ---------------- E-Bike ----------------
  'specialized_kenevo_sl': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'specialized_levo': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'trek_rail': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'canyon_spectral_on': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'giant_reign_e': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air
  'yt_decoy': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'orbea_wild': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'norco_sight_vlt': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air

  // ================= Enduro =================
  'yeti_sb165': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'yeti_sb160': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'gt_force': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'norco_range_2022': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'specialized_enduro_2021': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'santacruz_megatower_2020': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 (36 statt 38 in Gen1) / Fox X2 Factory
  'trek_slash_2023': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air
  'canyon_strive_2022': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'commencal_meta_am_2023': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'nicolai_g1': _params(forkOhlinsRXF, shockRockshoxSuperDeluxeUltimateAir), // Öhlins RXF38 m.2 / RockShox Super Deluxe Ultimate Air (typische Custom-Kombination)
  'nicolai_saturn14': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'last_tarvis': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'polygon_collosus_n9': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'norco_shore': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'canfield_jedi': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'geometron_g16': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'pole_evolink': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'stanton_slackline': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air
  'saracen_kiliflyer': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'yt_capra_2022': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'propain_hugene': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'giant_reign_2023': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air

  // ================= Trail =================
  'rockymountain_instinct': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'vitus_escarpe': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'santacruz_5010': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34/36 Factory GRIP2 / Fox Float X Factory
  'santacruz_tallboy': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34 Factory GRIP2 / Fox Float X Factory
  'pivot_switchblade': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'transition_scout': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike/Lyrik Ultimate / Super Deluxe Ultimate Air
  'norco_optic': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike Ultimate / Super Deluxe Ultimate Air
  'norco_fluid': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'marin_rift_zone': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike Ultimate / Super Deluxe Ultimate Air
  'marin_wolf_ridge': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'radon_skeen': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'merida_ninety_six': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34 Factory GRIP2 / Fox Float X Factory
  'commencal_meta_tr': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'cube_stereo_150': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'scott_genius': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory (TwinLoc)
  'polygon_siskiu': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'whyte_t130': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike Ultimate / Super Deluxe Ultimate Air
  'lapierre_zesty': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'ghost_kato': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34/36 Factory GRIP2 / Fox Float X Factory
  'bold_linkin': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'propain_yuma': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34 Factory GRIP2 / Fox Float X Factory
  'liteville_601': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory

  // ================= Downhill =================
  'santacruz_v10_2019': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'specialized_demo_2016': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer World Cup / Vivid Coil (ältere Generation)
  'propain_rage': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'intense_m279': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'foes_mixer': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'last_herb': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'nicolai_ion16': _params(forkOhlinsRXF, shockFoxDHX2FactoryCoil), // Öhlins DH38 m.2 (RXF-Profil als Näherung) / Fox DHX2 Factory Coil
  'polygon_collosus_dh': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'trek_session_2022': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate
  'yt_tues_2021': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'commencal_supreme_dh_2020': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 40 Factory GRIP2 / Fox DHX2 Factory Coil
  'devinci_wilson_2023': _params(forkRockshoxChargerRC2, shockRockshoxVividCoilUltimate), // RockShox BoXXer Ultimate / Vivid Coil Ultimate

  // ================= All Mountain =================
  'transition_spire_alloy': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'specialized_stumpjumper_alloy': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Select+ / Super Deluxe Select+ (vereinfacht Ultimate-Profil)
  'ibis_ripley': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34 Factory GRIP2 / Fox Float X Factory
  'rockymountain_pipeline': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'kona_heihei': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Pike Ultimate / Super Deluxe Ultimate Air
  'evil_following': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34 Factory GRIP2 / Fox Float X Factory
  'privateer_161': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'deviate_claymore': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'cotic_rocketmax': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'antidote_darkmatter': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 36 Factory GRIP2 / Fox Float X Factory
  'banshee_titan': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'knolly_chilcotin': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'guerrillagravity_smash': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'yeti_sb130': _params(forkFoxFactoryGrip2, shockFoxFloatXFactory), // Fox 34/36 Factory GRIP2 / Fox Float X Factory

  // ================= Cross Country =================
  'trek_top_fuel': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory
  'specialized_epic_evo': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory
  'canyon_lux': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'yt_izzo': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory
  'orbea_oiz': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'pivot_mach4sl': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / Fox Float SL Factory
  'bmc_fourstroke': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'vitus_sentier': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'stevens_jura': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'simplon_kamerad': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / Fox Float SL Factory
  'ghost_lector': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory
  'norco_revolver': _params(forkRockshoxSIDUltimate, shockRockshoxSIDLuxeUltimate), // RockShox SID Ultimate / SIDLuxe Ultimate
  'rockymountain_element': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory
  'intense_sniper': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / Fox Float SL Factory
  'cube_ams_100': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 32 SC Factory / Fox Float SL Factory
  'scott_spark_2021': _params(forkFoxFactorySL, shockFoxFloatSLFactory), // Fox 34 SC Factory / Fox Float SL Factory (TwinLoc, ältere Generation)

  // ================= E-Bike =================
  'trek_fuel_exe': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'specialized_kenevo': _params(forkFoxFactoryGrip2, shockFoxDHX2FactoryCoil), // Fox 38 Factory GRIP2 / Fox DHX2 Factory Coil
  'cannondale_moterra': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air
  'transition_relay': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'pivot_shuttle_am': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'merida_eonesixty': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'whyte_e180': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'lapierre_overvolt': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox ZEB Ultimate / Super Deluxe Ultimate Air
  'ghost_hybride_riot': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 38 Factory GRIP2 / Fox X2 Factory
  'focus_thron': _params(forkFoxFactoryGrip2, shockFoxFloatX2Factory), // Fox 36 Factory GRIP2 / Fox X2 Factory
  'norco_range_vlt': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'canyon_neuron_on': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
  'rockymountain_altitude_powerplay': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeCoilUltimate), // RockShox ZEB Ultimate / Super Deluxe Coil Ultimate
  'kona_remote': _params(forkRockshoxChargerRC2, shockRockshoxSuperDeluxeUltimateAir), // RockShox Lyrik Ultimate / Super Deluxe Ultimate Air
};
