#!/usr/bin/env swift
// Renders the ShareBank app icon: an arrow rising out of an open-topped vault.
//
//   swift Tools/GenerateAppIcon.swift
//
// Writes the light, dark, and tinted 1024pt variants into the app's asset catalog.

import AppKit
import CoreGraphics
import Foundation

let size = 1024.0

struct Variant {
  let name: String
  /// `nil` leaves the background transparent, which is what the dark and tinted variants need —
  /// iOS composites those over a background of its own.
  let gradient: (top: CGColor, bottom: CGColor)?
  let glyphColor: CGColor
}

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
  CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

let variants = [
  Variant(
    name: "AppIcon",
    gradient: (top: rgb(96, 92, 255), bottom: rgb(146, 51, 234)),
    glyphColor: .white
  ),
  Variant(name: "AppIcon-Dark", gradient: nil, glyphColor: .white),
  Variant(name: "AppIcon-Tinted", gradient: nil, glyphColor: .white),
]

/// Draws in a top-left origin coordinate space, the way the shape is measured.
func draw(_ variant: Variant, into context: CGContext) {
  if let colors = variant.gradient {
    context.saveGState()
    let gradient = CGGradient(
      colorsSpace: CGColorSpaceCreateDeviceRGB(),
      colors: [colors.top, colors.bottom] as CFArray,
      locations: [0, 1]
    )!
    context.drawLinearGradient(
      gradient,
      start: CGPoint(x: 0, y: size),
      end: CGPoint(x: size, y: 0),
      options: []
    )
    context.restoreGState()
  }

  // Flip to a top-left origin so the glyph coordinates read like a design spec.
  context.saveGState()
  context.translateBy(x: 0, y: size)
  context.scaleBy(x: 1, y: -1)

  context.setStrokeColor(variant.glyphColor)
  context.setLineWidth(78)
  context.setLineCap(.round)
  context.setLineJoin(.round)

  // The vault: a rounded container open at the top.
  let vault = CGMutablePath()
  let left = 268.0, right = 756.0, top = 556.0, bottom = 830.0, radius = 76.0
  vault.move(to: CGPoint(x: left, y: top))
  vault.addLine(to: CGPoint(x: left, y: bottom - radius))
  vault.addArc(
    tangent1End: CGPoint(x: left, y: bottom),
    tangent2End: CGPoint(x: left + radius, y: bottom),
    radius: radius
  )
  vault.addLine(to: CGPoint(x: right - radius, y: bottom))
  vault.addArc(
    tangent1End: CGPoint(x: right, y: bottom),
    tangent2End: CGPoint(x: right, y: bottom - radius),
    radius: radius
  )
  vault.addLine(to: CGPoint(x: right, y: top))
  context.addPath(vault)
  context.strokePath()

  // The arrow leaving it.
  let stem = CGMutablePath()
  stem.move(to: CGPoint(x: 512, y: 726))
  stem.addLine(to: CGPoint(x: 512, y: 268))
  context.addPath(stem)
  context.strokePath()

  let head = CGMutablePath()
  head.move(to: CGPoint(x: 366, y: 414))
  head.addLine(to: CGPoint(x: 512, y: 268))
  head.addLine(to: CGPoint(x: 658, y: 414))
  context.addPath(head)
  context.strokePath()

  context.restoreGState()
}

let assetPath = "App/Assets.xcassets/AppIcon.appiconset"

for variant in variants {
  guard
    let context = CGContext(
      data: nil,
      width: Int(size),
      height: Int(size),
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { fatalError("could not create bitmap context") }

  draw(variant, into: context)

  guard let image = context.makeImage() else { fatalError("could not render \(variant.name)") }
  let bitmap = NSBitmapImageRep(cgImage: image)
  guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("could not encode \(variant.name)")
  }
  let url = URL(fileURLWithPath: "\(assetPath)/\(variant.name).png")
  try data.write(to: url)
  print("wrote \(url.path)")
}
