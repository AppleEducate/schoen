_ = require 'underscore'
{FretCount, FretNumbers} = require './instruments'

#
# Style
#

{hsv2css} = require './utils'

SmallStyle =
  h_gutter: 5
  v_gutter: 5
  string_spacing: 6
  fret_height: 8
  above_fretboard: 8
  note_radius: 1
  closed_string_fontsize: 4
  chord_degree_colors: ['red', 'blue', 'green', 'orange']
  intervalClass_colors: [0...12].map (n) ->
    # i = (7 * n) % 12  # color by circle of fifth ascension
    hsv2css h: n * 360 / 12, s: 1, v: 1

DefaultStyle = _.extend {}, SmallStyle,
  string_spacing: 12
  fret_height: 16
  note_radius: 3
  closed_string_fontsize: 8

computeChordDiagramDimensions = (instrument, style=DefaultStyle) ->
  {
    width: 2 * style.h_gutter + (instrument.strings - 1) * style.string_spacing
    height: 2 * style.v_gutter + (style.fret_height + 2) * FretCount
  }


#
# Drawing Methods
#

drawChordDiagramStrings = (ctx, instrument, options={}) ->
  style = DefaultStyle
  for string in instrument.stringNumbers
    x = string * style.string_spacing + style.h_gutter
    ctx.beginPath()
    ctx.moveTo x, style.v_gutter + style.above_fretboard
    ctx.lineTo x, style.v_gutter + style.above_fretboard + FretCount * style.fret_height
    ctx.strokeStyle = (if options.dimStrings and string in options.dimStrings then 'rgba(0,0,0,0.2)' else 'black')
    ctx.stroke()

drawChordDiagramFrets = (ctx, instrument, {drawNut}={drawNut: true}) ->
  style = DefaultStyle
  ctx.strokeStyle = 'black'
  for fret in FretNumbers
    y = style.v_gutter + style.above_fretboard + fret * style.fret_height
    ctx.beginPath()
    ctx.moveTo style.v_gutter - 0.5, y
    ctx.lineTo style.v_gutter + 0.5 + (instrument.strings - 1) * style.string_spacing, y
    ctx.lineWidth = 3 if fret == 0 and drawNut
    ctx.stroke()
    ctx.lineWidth = 1

drawChordDiagram = (ctx, instrument, positions, options={}) ->
  defaults = {drawClosedStrings: true, drawNut: true, dy: 0, style: DefaultStyle}
  options = _.extend defaults, options
  {barres, dy, drawClosedStrings, drawNut, style} = options

  topFret = 0
  frets = (fret for {fret} in positions when fret != 0)
  lowestFret = Math.min(frets...)
  highestFret = Math.max(frets...)
  if highestFret > 4
    topFret = lowestFret - 1
    drawNut = false

  if options.dimUnusedStrings
    usedStrings = (string for {string} in positions)
    options.dimStrings = (string for string in instrument.stringNumbers when string not in usedStrings)

  fingerCoordinates = ({string, fret}) ->
    fret -= topFret if fret > 0
    return {
      x: style.h_gutter + string * style.string_spacing,
      y: style.v_gutter + style.above_fretboard + (fret - 0.5) * style.fret_height + dy
    }

  drawFingerPosition = (position, options={}) ->
    {isRoot, color} = options
    {x, y} = fingerCoordinates(position)
    ctx.fillStyle = color or (if isRoot then 'red' else 'white')
    ctx.strokeStyle = color or (if isRoot then 'red' else 'black')
    ctx.lineWidth = 1
    ctx.beginPath()
    if isRoot and position.fret
      do (r=style.note_radius) ->
        ctx.rect x - r, y - r, 2 * r, 2 * r
    else
      ctx.arc x, y, style.note_radius, 0, Math.PI * 2, false
    ctx.fill() if position.fret > 0 or isRoot
    ctx.stroke()

  drawBarres = ->
    ctx.fillStyle = 'black'
    for {fret, firstString, stringCount} in barres
      {x: x1, y} = fingerCoordinates {string: firstString, fret}
      {x: x2} = fingerCoordinates {string: firstString + stringCount - 1, fret}
      w = x2 - x1
      ctx.save()
      ctx.translate (x1 + x2) / 2, y - style.fret_height * .25
      ctx.beginPath()
      eccentricity = 10
      do ->
        ctx.save()
        ctx.scale w, eccentricity
        ctx.arc 0, 0, style.string_spacing / 2 / eccentricity, Math.PI, 0, false
        ctx.restore()
      do ->
        ctx.save()
        ctx.scale w, 14
        ctx.arc 0, 0, style.string_spacing / 2 / eccentricity, 0, Math.PI, true
        ctx.restore()
      ctx.fill()
      ctx.restore()
      # ctx.fillStyle = 'rgba(0,0,0, 0.5)'
      # ctx.beginPath()
      # ctx.arc x1, y, style.string_spacing / 2, Math.PI * 1/2, Math.PI * 3/2, false
      # ctx.arc x2, y, style.string_spacing / 2, Math.PI * 3/2, Math.PI * 1/2, false
      # ctx.fill()

  drawFingerPositions = ->
    for position in positions
      default_options =
        color: style.intervalClass_colors[position.intervalClass.semitones]
        isRoot: (position.intervalClass == 0)
      drawFingerPosition position, _.extend(default_options, position)

  drawClosedStrings = ->
    fretted_strings = []
    fretted_strings[position.string] = true for position in positions
    closed_strings = (string for string in instrument.stringNumbers when not fretted_strings[string])
    r = style.note_radius
    ctx.fillStyle = 'black'
    for string in closed_strings
      {x, y} = fingerCoordinates {string, fret: 0}
      ctx.strokeStyle = 'black'
      ctx.beginPath()
      ctx.moveTo x - r, y - r
      ctx.lineTo x + r, y + r
      ctx.moveTo x - r, y + r
      ctx.lineTo x + r, y - r
      ctx.stroke()

  drawChordDiagramStrings ctx, instrument, options
  drawChordDiagramFrets ctx, instrument, drawNut: drawNut
  drawBarres() if barres
  drawFingerPositions() if positions
  drawClosedStrings() if positions and options.drawClosedStrings
  return {topFret}

module.exports =
  defaultStyle: DefaultStyle
  width: (instrument) -> computeChordDiagramDimensions(instrument).width
  height: (instrument) -> computeChordDiagramDimensions(instrument).height
  draw: drawChordDiagram
