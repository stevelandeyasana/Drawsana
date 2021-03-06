//
//  ViewController.swift
//  AMDrawingView Demo
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit
import Drawsana
import QuickLook

/**
 Bare-bones demonstration of the Drawsana API. Drawsana does not provide its
 own UI, so this demo has a very simple one.
 */
class ViewController: UIViewController {
  lazy var drawingView: DrawsanaView = {
    let drawingView = DrawsanaView()
    drawingView.delegate = self
    drawingView.operationStack.delegate = self
    return drawingView
  }()

  let toolButton = UIButton(type: .custom)
  let imageView = UIImageView(image: UIImage(named: "demo"))
  let undoButton = UIButton()
  let redoButton = UIButton()
  let viewFinalImageButton = UIButton()
  let strokeColorButton = UIButton()
  let fillColorButton = UIButton()
  let strokeWidthButton = UIButton()
  lazy var toolbarStackView = {
    return UIStackView(arrangedSubviews: [
      undoButton,
      redoButton,
      strokeColorButton,
      fillColorButton,
      strokeWidthButton,
      toolButton,
      viewFinalImageButton,
    ])
  }()

  /// Instance of `TextTool` for which we are the delegate, so we can respond
  /// to relevant UI events
  lazy var textTool = { return TextTool(delegate: self) }()

  /// Instance of `SelectionTool` for which we are the delegate, so we can
  /// respond to relevant UI events
  lazy var selectionTool = { return SelectionTool(delegate: self) }()

  lazy var tools: [DrawingTool] = { return [
    PenTool(),
    textTool,
    selectionTool,
    EllipseTool(),
    EraserTool(),
    LineTool(),
    ArrowTool(),
    RectTool(),
  ] }()
  var toolIndex = 0

  let colors: [UIColor?] = [
    .blue,
    .yellow,
    nil
  ]
  var strokeColorIndex = 0
  var fillColorIndex = 2

  let strokeWidths: [CGFloat] = [
    5,
    10,
    20,
  ]
  var strokeWidthIndex = 0

  // Just AutoLayout code here
  override func loadView() {
    self.view = UIView()

    toolButton.translatesAutoresizingMaskIntoConstraints = false
    toolButton.setTitle("No Tool", for: .normal)
    toolButton.addTarget(self, action: #selector(changeTool(_:)), for: .touchUpInside)
    toolButton.setContentHuggingPriority(.required, for: .vertical)

    undoButton.translatesAutoresizingMaskIntoConstraints = false
    undoButton.setTitle("<", for: .normal)
    undoButton.addTarget(drawingView.operationStack, action: #selector(DrawingOperationStack.undo), for: .touchUpInside)

    redoButton.translatesAutoresizingMaskIntoConstraints = false
    redoButton.setTitle(">", for: .normal)
    redoButton.addTarget(drawingView.operationStack, action: #selector(DrawingOperationStack.redo), for: .touchUpInside)

    viewFinalImageButton.translatesAutoresizingMaskIntoConstraints = false
    viewFinalImageButton.setTitle("👁", for: .normal)
    viewFinalImageButton.addTarget(self, action: #selector(ViewController.viewFinalImage(_:)), for: .touchUpInside)

    strokeColorButton.translatesAutoresizingMaskIntoConstraints = false
    strokeColorButton.addTarget(self, action: #selector(ViewController.cycleStrokeColor(_:)), for: .touchUpInside)
    strokeColorButton.layer.borderColor = UIColor.white.cgColor
    strokeColorButton.layer.borderWidth = 0.5

    fillColorButton.translatesAutoresizingMaskIntoConstraints = false
    fillColorButton.addTarget(self, action: #selector(ViewController.cycleFillColor(_:)), for: .touchUpInside)
    fillColorButton.layer.borderColor = UIColor.white.cgColor
    fillColorButton.layer.borderWidth = 0.5

    strokeWidthButton.translatesAutoresizingMaskIntoConstraints = false
    strokeWidthButton.addTarget(self, action: #selector(ViewController.cycleStrokeWidth(_:)), for: .touchUpInside)
    strokeWidthButton.layer.borderColor = UIColor.white.cgColor
    strokeWidthButton.layer.borderWidth = 0.5

    toolbarStackView.translatesAutoresizingMaskIntoConstraints = false
    toolbarStackView.axis = .horizontal
    toolbarStackView.distribution = .equalSpacing
    toolbarStackView.alignment = .fill
    view.addSubview(toolbarStackView)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .gray
    view.addSubview(imageView)

    drawingView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(drawingView)

    let imageAspectRatio = imageView.image!.size.width / imageView.image!.size.height

    NSLayoutConstraint.activate([
      // imageView constrain to left/top/right
      imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
      imageView.rightAnchor.constraint(equalTo: view.rightAnchor),
      imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

      // toolbarStackView fill bottom
      toolbarStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      toolbarStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      toolbarStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),

      // imageView bottom -> toolbarStackView.top
      imageView.bottomAnchor.constraint(equalTo: toolbarStackView.topAnchor),

      // drawingView is centered in imageView, shares image's aspect ratio,
      // and doesn't expand past its frame
      drawingView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      drawingView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
      drawingView.widthAnchor.constraint(lessThanOrEqualTo: imageView.widthAnchor),
      drawingView.heightAnchor.constraint(lessThanOrEqualTo: imageView.heightAnchor),
      drawingView.widthAnchor.constraint(equalTo: drawingView.heightAnchor, multiplier: imageAspectRatio),
      drawingView.widthAnchor.constraint(equalTo: imageView.widthAnchor).withPriority(.defaultLow),
      drawingView.heightAnchor.constraint(equalTo: imageView.heightAnchor).withPriority(.defaultLow),

      // Color buttons have constant size
      strokeColorButton.widthAnchor.constraint(equalToConstant: 30),
      strokeColorButton.heightAnchor.constraint(equalToConstant: 30),
      fillColorButton.widthAnchor.constraint(equalToConstant: 30),
      fillColorButton.heightAnchor.constraint(equalToConstant: 30),
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set initial tool to whatever `toolIndex` says
    drawingView.set(tool: tools[toolIndex])
    drawingView.userSettings.strokeColor = colors[strokeColorIndex]
    drawingView.userSettings.fillColor = colors[fillColorIndex]
    drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
    drawingView.userSettings.fontName = "Marker Felt"
    applyViewState()
  }

  /// Cycle to the next tool in the list; wrap around to zeroth tool if at end
  @objc private func changeTool(_ sender: Any?) {
    toolIndex = (toolIndex + 1) % tools.count
    drawingView.set(tool: tools[toolIndex])
    applyViewState()
  }

  var savedImageURL: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("drawsana_demo").appendingPathExtension("jpg")
  }

  /// Show rendered image in a separate view
  @objc private func viewFinalImage(_ sender: Any?) {
    // Dump JSON to console just to demonstrate
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try! jsonEncoder.encode(drawingView.drawing)
    print(String(data: jsonData, encoding: .utf8)!)

    // Decode as a sanity check in lieu of unit tests
    let jsonDecoder = JSONDecoder()
    let _ = try! jsonDecoder.decode(Drawing.self, from: jsonData)

    guard
      let image = drawingView.render(over: imageView.image),
      let data = UIImageJPEGRepresentation(image, 0.75),
      (try? data.write(to: savedImageURL)) != nil else
    {
      assert(false, "Can't create or save image")
      return
    }
    let vc = QLPreviewController(nibName: nil, bundle: nil)
    vc.dataSource = self
    present(vc, animated: true, completion: nil)
  }

  @objc private func cycleStrokeColor(_ sender: Any?) {
    strokeColorIndex = (strokeColorIndex + 1) % colors.count
    drawingView.userSettings.strokeColor = colors[strokeColorIndex]
    applyViewState()
  }

  @objc private func cycleFillColor(_ sender: Any?) {
    fillColorIndex = (fillColorIndex + 1) % colors.count
    drawingView.userSettings.fillColor = colors[fillColorIndex]
    applyViewState()
  }

  @objc private func cycleStrokeWidth(_ sender: Any?) {
    strokeWidthIndex = (strokeWidthIndex + 1) % strokeWidths.count
    drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
    applyViewState()
  }

  /// Update button states to reflect undo stack and user settings
  private func applyViewState() {
    undoButton.isEnabled = drawingView.operationStack.canUndo
    redoButton.isEnabled = drawingView.operationStack.canRedo
    toolButton.setTitle(tools[toolIndex].name, for: .normal)
    strokeColorButton.backgroundColor = colors[strokeColorIndex]
    fillColorButton.backgroundColor = colors[fillColorIndex]

    strokeColorButton.setTitle(colors[strokeColorIndex] == nil ? "x" : "", for: .normal)
    fillColorButton.setTitle(colors[fillColorIndex] == nil ? "x" : "", for: .normal)
    strokeWidthButton.setTitle("\(Int(strokeWidths[strokeWidthIndex]))", for: .normal)

    for button in [undoButton, redoButton] {
      button.alpha = button.isEnabled ? 1 : 0.5
    }
  }
}

extension ViewController: DrawsanaViewDelegate {
  /// When tool changes, update the UI
  func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool) {
    toolIndex = tools.index(where: { $0.name == tool.name })!
    applyViewState()
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didStartDragWith tool: DrawingTool) {
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didEndDragWith tool: DrawingTool) {
  }
}

extension ViewController: SelectionToolDelegate {
  /// When a shape is double-tapped by the selection tool, and it's text,
  /// begin editing the text
  func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable) {
    if shape as? TextShape != nil {
      drawingView.set(tool: textTool, shape: shape)
    } else {
      drawingView.toolSettings.selectedShape = nil
    }
  }
}

extension ViewController: TextToolDelegate {
  /// Don't modify text point. In reality you probably do want to modify it to
  /// make sure it's not below the keyboard.
  func textToolPointForNewText(tappedPoint: CGPoint) -> CGPoint {
    return tappedPoint
  }

  /// When user taps away from text, switch to the selection tool so they can
  /// tap anything they want.
  func textToolDidTapAway(tappedPoint: CGPoint) {
    toolIndex = tools.index(where: { ($0 as? SelectionTool) === self.selectionTool })!
    drawingView.set(tool: tools[toolIndex])
  }

  func textToolWillUseEditingView(_ editingView: TextShapeEditingView) {
    for view in [editingView.deleteControlView, editingView.resizeAndRotateControlView] {
      view.backgroundColor = .black
      view.layer.cornerRadius = 6
      view.layer.borderWidth = 1
      view.layer.borderColor = UIColor.white.cgColor
      view.layer.shadowColor = UIColor.black.cgColor
      view.layer.shadowOffset = CGSize(width: 1, height: 1)
      view.layer.shadowRadius = 3
      view.layer.shadowOpacity = 0.5
    }
    let deleteImageView = UIImageView(image: UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate))
    let rotateImageView = UIImageView(image: UIImage(named: "rotate")?.withRenderingMode(.alwaysTemplate))

    for (controlView, imageView) in [(editingView.deleteControlView, deleteImageView), (editingView.resizeAndRotateControlView, rotateImageView)] {
      controlView.frame = CGRect(origin: .zero, size: CGSize(width: 16, height: 16))
      imageView.translatesAutoresizingMaskIntoConstraints = true
      imageView.frame = controlView.bounds.insetBy(dx: 4, dy: 4)
      imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      imageView.contentMode = .scaleAspectFit
      imageView.tintColor = .white
      controlView.addSubview(imageView)
    }
  }
}

/// Implement `DrawingOperationStackDelegate` to keep the UI in sync with the
/// operation stack
extension ViewController: DrawingOperationStackDelegate {
  func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    applyViewState()
  }

  func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    applyViewState()
  }

  func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    applyViewState()
  }
}

extension ViewController: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return savedImageURL as NSURL
  }
}

private extension NSLayoutConstraint {
  func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
    self.priority = priority
    return self
  }
}
