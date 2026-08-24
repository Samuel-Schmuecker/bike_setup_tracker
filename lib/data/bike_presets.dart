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
};