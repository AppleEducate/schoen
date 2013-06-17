_ = require 'underscore'

NoteNames = "G# A A# B C C# D D# E F F# G".split(/\s/)

IntervalNames = ['P1', 'm2', 'M2', 'm3', 'M3', 'P4', 'TT', 'P5', 'm6', 'M6', 'm7', 'M7', 'P8']

LongIntervalNames = [
  'Unison', 'Minor 2nd', 'Major 2nd', 'Minor 3rd', 'Major 3rd', 'Perfect 4th',
  'Tritone', 'Perfect 5th', 'Minor 6th', 'Major 6th', 'Minor 7th', 'Major 7th', 'Octave']

Scales = do ->
  scale_specs = [
    'Diatonic Major: 024579e'
    'Natural Minor: 023578t'
    'Melodic Minor: 023579e'
    'Harmonic Minor: 023578e'
    'Pentatonic Major: 02479'
    'Pentatonic Minor: 0357t'
    'Blues: 03567t'
    'Freygish: 014578t'
    'Whole Tone: 02468t'
    # 'Octatonic' is the classical name. It's the jazz 'Diminished' scale.
    'Octatonic: 0235689e'
  ]
  scales = []
  for spec, i in scale_specs
    [name, tones] = spec.split(/:\s*/, 2)
    tones = _.map tones, (c) -> {'t':10, 'e':11}[c] or Number(c)
    # console.info 'set', name, i
    scales[name] = scales[i] = {name, tones}
  scales

Modes = do (root_tones=Scales['Diatonic Major'].tones) ->
  mode_names = 'Ionian Dorian Phrygian Lydian Mixolydian Aeolian Locrian'.split(/\s/)
  modes = []
  for displacement, i in root_tones
    name = mode_names[i]
    tones = ((d - displacement + 12) % 12 for d in root_tones[i...].concat root_tones[...i])
    modes[name] = modes[i] = {name, degree: i, tones}
  modes

# Indexed by scale degree
Functions = 'Tonic Supertonic Mediant Subdominant Dominant Submediant Subtonic Leading'.split(/\s/)

class Chord
  constructor: (options) ->
    @name = options.name
    @full_name = options.full_name
    @abbrs = options.abbrs or [options.abbr]
    @abbrs = @abbrs.split(/s/) if typeof @abbrs == 'string'
    @abbr = options.abbr or @abbrs[0]
    @pitch_classes = options.pitch_classes
    @root = options.root
    @root = NoteNames.indexOf @root if typeof @root == 'string'
    degrees = (1 + 2 * i for i in [0..@pitch_classes.length])
    degrees[1] = {'Sus2':2, 'Sus4':4}[@name] || degrees[1]
    degrees[3] = 6 if @name.match /6/
    @components = for pc, pci in @pitch_classes
      name = IntervalNames[pc]
      degree = degrees[pci]
      if pc == 0
        name = 'R'
      else unless Number(name.match(/\d+/)?[0]) == degree
        name = "A#{degree}" if Number(IntervalNames[pc - 1].match(/\d+/)?[0]) == degree
        name = "d#{degree}" if Number(IntervalNames[pc + 1].match(/\d+/)?[0]) == degree
      name
    if typeof @root == 'number'
      Object.defineProperty this, 'name', get: ->
        "#{NoteNames[@root]}#{@abbr}"

  at: (root) ->
    new Chord
      name: @name
      full_name: @full_name
      abbrs: @abbrs
      pitch_classes: @pitch_classes
      root: root

  degree_name: (degree_index) ->
    @components[degree_index]

ChordDefinitions = [
  {name: 'Major', abbrs: ['', 'M'], pitch_classes: '047'},
  {name: 'Minor', abbr: 'm', pitch_classes: '037'},
  {name: 'Augmented', abbrs: ['+', 'aug'], pitch_classes: '048'},
  {name: 'Diminished', abbrs: ['°', 'dim'], pitch_classes: '036'},
  {name: 'Sus2', abbr: 'sus2', pitch_classes: '027'},
  {name: 'Sus4', abbr: 'sus4', pitch_classes: '057'},
  {name: 'Dominant 7th', abbrs: ['7', 'dom7'], pitch_classes: '047t'},
  {name: 'Augmented 7th', abbrs: ['+7', '7aug'], pitch_classes: '048t'},
  {name: 'Diminished 7th', abbrs: ['°7', 'dim7'], pitch_classes: '0369'},
  {name: 'Major 7th', abbr: 'maj7', pitch_classes: '047e'},
  {name: 'Minor 7th', abbr: 'min7', pitch_classes: '037t'},
  {name: 'Dominant 7b5', abbr: '7b5', pitch_classes: '046t'},
  # following is also half-diminished 7th
  {name: 'Minor 7th b5', abbrs: ['ø', 'Ø', 'm7b5'], pitch_classes: '036t'},
  {name: 'Diminished` Maj 7th', abbr: '°Maj7', pitch_classes: '036e'},
  {name: 'Minor-Major 7th', abbrs: ['min/maj7', 'min(maj7)'], pitch_classes: '037e'},
  {name: '6th', abbrs: ['6', 'M6', 'M6', 'maj6'], pitch_classes: '0479'},
  {name: 'Minor 6th', abbrs: ['m6', 'min6'], pitch_classes: '0379'},
]

Chords = ChordDefinitions.map (spec) ->
  spec.full_name = spec.name
  spec.name = spec.name
    .replace(/Major(?!$)/, 'Maj')
    .replace(/Minor(?!$)/, 'Min')
    .replace('Dominant', 'Dom')
    .replace('Diminished', 'Dim')
  spec.abbrs or= [spec.abbr]
  spec.abbrs = spec.abbrs.split(/s/) if typeof spec.abbrs == 'string'
  spec.abbr or= spec.abbrs[0]
  spec.pitch_classes = _.map spec.pitch_classes, (c) -> {'t':10, 'e':11}[c] or Number(c)
  new Chord spec


interval_class_between = (pca, pcb) ->
  n = (pcb - pca) % 12
  n += 12 while n < 0
  return n

module.exports = {
  Chords
  IntervalNames
  LongIntervalNames
  Modes
  NoteNames
  Scales
  interval_class_between
}
