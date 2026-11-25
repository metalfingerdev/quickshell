.pragma library

// hyprglass's settings (its README's table): what Advanced offers, and what HyprLua.glass accepts.
// Defaults here are the plugin's own; brightness, contrast and the others it leaves per theme show as 1/0 until set.
var entries = [
 {
  "key": "blur_strength",
  "kind": "number",
  "def": 2,
  "min": 0,
  "max": 10,
  "label": "Blur radius scale"
 },
 {
  "key": "blur_iterations",
  "kind": "number",
  "def": 3,
  "min": 1,
  "max": 5,
  "label": "Blur passes"
 },
 {
  "key": "noise_strength",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Frosted grain"
 },
 {
  "key": "refraction_strength",
  "kind": "number",
  "def": 0.6,
  "min": 0,
  "max": 1,
  "label": "Edge refraction"
 },
 {
  "key": "refraction_flow",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Refraction flow"
 },
 {
  "key": "refraction_spread",
  "kind": "number",
  "def": 1,
  "min": 0,
  "max": 1,
  "label": "Refraction depth"
 },
 {
  "key": "chromatic_aberration",
  "kind": "number",
  "def": 0.5,
  "min": 0,
  "max": 1,
  "label": "Colour fringing"
 },
 {
  "key": "fresnel_strength",
  "kind": "number",
  "def": 0.6,
  "min": 0,
  "max": 1,
  "label": "Edge glow"
 },
 {
  "key": "fresnel_tint",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Edge glow takes the colours behind"
 },
 {
  "key": "fresnel_color",
  "kind": "colour",
  "def": "#ffffff00",
  "min": 0,
  "max": 0,
  "label": "Edge glow colour"
 },
 {
  "key": "specular_strength",
  "kind": "number",
  "def": 0.8,
  "min": 0,
  "max": 1,
  "label": "Specular highlight"
 },
 {
  "key": "specular_angle",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 360,
  "label": "Highlight angle"
 },
 {
  "key": "bevel_strength",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Bevel line"
 },
 {
  "key": "bevel_size",
  "kind": "number",
  "def": 6,
  "min": 0,
  "max": 60,
  "label": "Bevel width"
 },
 {
  "key": "bevel_color",
  "kind": "colour",
  "def": "#ffffff00",
  "min": 0,
  "max": 0,
  "label": "Bevel colour"
 },
 {
  "key": "bevel_tint",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Bevel takes the colours behind"
 },
 {
  "key": "bevel_angle",
  "kind": "number",
  "def": 315,
  "min": 0,
  "max": 360,
  "label": "Bevel light angle"
 },
 {
  "key": "bevel_shadow",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Bevel shadow"
 },
 {
  "key": "glass_opacity",
  "kind": "number",
  "def": 1,
  "min": 0,
  "max": 1,
  "label": "Glass opacity"
 },
 {
  "key": "edge_thickness",
  "kind": "number",
  "def": 0.06,
  "min": 0,
  "max": 0.15,
  "label": "Bezel width (fraction)"
 },
 {
  "key": "edge_thickness_px",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 200,
  "label": "Bezel width (px)"
 },
 {
  "key": "edge_height",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 500,
  "label": "Lens edge height"
 },
 {
  "key": "fresnel_reflection",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Lens mirrors the surroundings"
 },
 {
  "key": "tint_color",
  "kind": "colour",
  "def": "#8899aa22",
  "min": 0,
  "max": 0,
  "label": "Tint (alpha is its strength)"
 },
 {
  "key": "lens_distortion",
  "kind": "number",
  "def": 0.5,
  "min": 0,
  "max": 1,
  "label": "Centre magnification"
 },
 {
  "key": "self_sample",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Mix in the window's own content"
 },
 {
  "key": "xray",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "X-ray (1: wallpaper only)"
 },
 {
  "key": "focus_light",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Focus light"
 },
 {
  "key": "focus_light_color",
  "kind": "colour",
  "def": "#ffffff00",
  "min": 0,
  "max": 0,
  "label": "Focus light colour"
 },
 {
  "key": "frost",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 1,
  "label": "Frost"
 },
 {
  "key": "frost_blur",
  "kind": "number",
  "def": 3,
  "min": 0,
  "max": 10,
  "label": "Frost blur"
 },
 {
  "key": "brightness",
  "kind": "number",
  "def": 1,
  "min": 0,
  "max": 3,
  "label": "Brightness"
 },
 {
  "key": "contrast",
  "kind": "number",
  "def": 1,
  "min": 0,
  "max": 3,
  "label": "Contrast"
 },
 {
  "key": "saturation",
  "kind": "number",
  "def": 1,
  "min": 0,
  "max": 3,
  "label": "Saturation"
 },
 {
  "key": "vibrancy",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 2,
  "label": "Vibrancy"
 },
 {
  "key": "vibrancy_darkness",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 2,
  "label": "Vibrancy held back in the dark"
 },
 {
  "key": "adaptive_dim",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 2,
  "label": "Dim bright areas behind"
 },
 {
  "key": "adaptive_boost",
  "kind": "number",
  "def": 0,
  "min": 0,
  "max": 2,
  "label": "Boost dark areas behind"
 }
]

var known = (function () { const k = {}; entries.forEach(e => { k[e.key] = e.kind }); return k })()

// The built-in looks' own values (BuiltInPresets.hpp, v1.2.0), so a setting not yet touched shows what is
// drawn. Colours as "#rrggbbaa", as the settings keep them.
var looks = {
    "default": { shared: {} },
    high_contrast: { shared: {} },
    subtle: { shared: { blur_strength: 1, refraction_strength: 0.3, chromatic_aberration: 0.2, fresnel_strength: 0.3, specular_strength: 0.4 } },
    clear: { shared: { blur_strength: 0, noise_strength: 0, refraction_strength: 0.3, chromatic_aberration: 0.2, fresnel_strength: 0.3, specular_strength: 0.4 } },
    glass: { shared: { blur_strength: 1, blur_iterations: 2, lens_distortion: 0.3, refraction_strength: 8, chromatic_aberration: 0.5, fresnel_strength: 0.4,
                       specular_strength: 0.8, glass_opacity: 1, edge_thickness: 0.06, tint_color: "#ffffff00" },
             dark: { adaptive_dim: 0.3 }, light: { adaptive_boost: 0.3 } },
    pomme: { shared: { blur_strength: 1, blur_iterations: 2, refraction_strength: 2, refraction_flow: 1, refraction_spread: 1, chromatic_aberration: 0,
                       fresnel_strength: 0.1, fresnel_tint: 0, specular_strength: 0.4, bevel_strength: 0.5, bevel_size: 4, bevel_tint: 0.5,
                       glass_opacity: 1, edge_thickness: 0.024, lens_distortion: 0 },
             dark: { brightness: 1.1, contrast: 0.9, tint_color: "#1a1a1a4a" },
             light: { brightness: 0.8, contrast: 1, tint_color: "#ffffff6a" } }
}
