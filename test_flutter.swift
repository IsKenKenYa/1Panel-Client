import Cocoa
import FlutterMacOS

let engine = FlutterEngine(name: "my engine")
engine.run(withEntrypoint: nil)
let vc = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
