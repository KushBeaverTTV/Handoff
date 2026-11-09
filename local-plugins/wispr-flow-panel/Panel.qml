import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Wispr Flow (unofficial Linux port) — one bar icon carrying live dictation
// state; a click opens the panel with the actions, the way the shell's own
// weather, clock and audio widgets do it, and the way the Superwhisper panel
// beside it does.
//
// State comes from wispr-status.sh (process + PipeWire capture probe), actions
// go through the app's own wispr-flow:// deeplinks, and the Flow Bar pill is
// toggled by wispr-flowbar.sh editing the app's prefs.
Panel {
  id: root
  moduleName: "wispr-flow"
  ipcTarget: "wispr-flow"
  // This plugin owns its own IPC surface; the base's open/close/toggle would
  // otherwise claim the same target.
  manageIpc: false

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string pluginDir: root.home + "/.config/omarchy/plugins/wispr-flow-panel"
  readonly property string appBin: root.home + "/.local/bin/wispr-flow"

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color muted: Qt.darker(foreground, 1.55)
  readonly property color hairline: Qt.darker(foreground, 2.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // "off" | "idle" | "recording" | "processing"
  property string state: "off"
  readonly property bool appOn: root.state !== "off"
  readonly property bool recording: root.state === "recording"
  readonly property bool processing: root.state === "processing"
  // Superwhisper's own status palette: recording is its red (#E11414), the
  // bar's urgent role is a muted #a55555 on this theme that does not read as
  // "live" at a glance; transcribing takes its blue.
  readonly property color recordColor: "#E11414"
  readonly property color workColor: "#2B8DD4"
  readonly property color barIconColor: {
    if (root.recording) return root.recordColor
    if (root.processing) return root.workColor
    return root.foreground
  }

  readonly property string barPath1: "M48.1303 41.598C46.1328 41.598 44.2093 42.3748 42.8037 43.7804C41.361 45.1861 40.5842 47.1096 40.5842 49.0701V137.848C40.5842 138.847 40.7692 139.808 41.1391 140.733C41.509 141.658 42.0639 142.472 42.7667 143.174C43.4695 143.877 44.2833 144.432 45.2081 144.802C46.1328 145.172 47.0946 145.357 48.0933 145.357C50.0908 145.357 52.0144 144.58 53.42 143.174C54.8257 141.769 55.6395 139.882 55.6395 137.885V49.0701C55.6395 47.0726 54.8626 45.1861 53.42 43.7804C52.0144 42.3748 50.0908 41.598 48.0933 41.598H48.1303Z"
  readonly property string barPath2: "M93.4069 58.5766C92.4081 58.5766 91.4464 58.7615 90.5216 59.1314C89.5968 59.5014 88.783 60.0562 88.0802 60.759C87.3774 61.4619 86.8225 62.2757 86.4526 63.2004C86.0827 64.1252 85.8608 65.0869 85.8608 66.0487V120.166C85.8608 122.164 86.6376 124.05 88.0802 125.456C89.4859 126.861 91.4094 127.638 93.4069 127.638C95.4044 127.638 97.3279 126.861 98.7336 125.456C100.139 124.05 100.953 122.164 100.953 120.166V66.0487C100.953 64.0512 100.176 62.1647 98.7336 60.759C97.3279 59.3534 95.4044 58.5766 93.4069 58.5766Z"
  readonly property string barPath3: "M70.7647 89.1309C68.7672 89.1309 66.8437 89.9077 65.4381 91.3134C64.0324 92.719 63.2186 94.6056 63.2186 96.6031V127.453C63.2186 129.451 63.9954 131.337 65.4381 132.743C66.8437 134.149 68.7672 134.925 70.7647 134.925C72.7622 134.925 74.6858 134.149 76.0914 132.743C77.497 131.337 78.3108 129.451 78.3108 127.453V96.6031C78.3108 94.6056 77.534 92.719 76.0914 91.3134C74.6858 89.9077 72.7622 89.1309 70.7647 89.1309Z"
  readonly property string barPath4: "M138.686 41.598C137.687 41.598 136.725 41.7829 135.8 42.1528C134.876 42.5227 134.062 43.0776 133.359 43.7804C132.656 44.4832 132.101 45.297 131.731 46.2218C131.361 47.1466 131.14 48.1083 131.14 49.0701V137.848C131.14 139.845 131.916 141.732 133.359 143.137C134.765 144.543 136.688 145.32 138.686 145.32C140.683 145.32 142.607 144.543 144.012 143.137C145.418 141.732 146.232 139.845 146.232 137.848V49.0701C146.232 47.0726 145.455 45.1861 144.012 43.7804C142.607 42.3748 140.683 41.598 138.686 41.598Z"
  readonly property string barPath5: "M116.043 89.1309C114.046 89.1309 112.122 89.9077 110.717 91.3134C109.311 92.719 108.497 94.6056 108.497 96.6031V127.453C108.497 129.451 109.274 131.337 110.717 132.743C112.122 134.149 114.046 134.925 116.043 134.925C118.041 134.925 119.964 134.149 121.37 132.743C122.776 131.337 123.59 129.451 123.59 127.453V96.6031C123.59 94.6056 122.813 92.719 121.37 91.3134C119.964 89.9077 118.041 89.1309 116.043 89.1309Z"

  readonly property string statusText: {
    if (root.state === "recording") return "Listening…"
    if (root.state === "processing") return "Transcribing…"
    if (root.state === "idle") return "Idle — ready to dictate"
    return "Not running"
  }

  // ---------------------------------------------------------------- state

  Process {
    id: statusProc
    command: ["bash", root.pluginDir + "/wispr-status.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        var s = String(this.text).trim()
        if (s === "off" || s === "idle" || s === "recording") root.state = s
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  Component.onCompleted: Qt.callLater(function() {
    statusProc.running = true
  })

  // ---------------------------------------------------------------- actions

  function startApp() {
    if (root.bar) root.bar.run(root.appBin)
  }

  function quitApp() {
    // Bracketed so the pattern cannot match the bar's own command line.
    if (root.bar) root.bar.run("pkill -f '[w]ispr-flow/usr/lib/wispr-flow/wispr-flow'")
  }

  function power() {
    if (root.appOn) root.quitApp()
    else root.startApp()
  }

  function openHub() {
    if (root.bar) root.bar.run("xdg-open wispr-flow://open")
  }

  function dictate() {
    if (root.recording) root.bar.run("xdg-open wispr-flow://stop-hands-free")
    else root.bar.run("xdg-open wispr-flow://start-hands-free")
  }

  // The app needs a moment to release the mic and the singleton lock before
  // it can start again.
  Timer {
    id: restartTimer
    interval: 1200
    onTriggered: root.startApp()
  }

  // The Flow Bar pill is patched out of the app's bundle; the bar icon is the
  // status indicator. Only app actions remain.
  function restartApp() {
    root.quitApp()
    restartTimer.start()
  }

  // Reachable from a keybinding or the command line:
  //   omarchy-shell wispr-flow open | toggle | status | dictate | power | restart
  IpcHandler {
    id: ipc
    target: root.ipcTarget
    function open(): string { root.openHub(); return "ok" }
    function toggle(): string { root.toggle(); return root.opened ? "open" : "closed" }
    function status(): string { return root.state }
    function dictate(): string { root.dictate(); return root.recording ? "stopping" : "starting" }
    function power(): string { root.power(); return root.appOn ? "stopping" : "starting" }
    function restart(): string { root.restartApp(); return "restarting" }
    Component.onCompleted: IpcRegistry.register(ipc)
    Component.onDestruction: IpcRegistry.unregister(ipc)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The bar carries the five-bar mark, sized like every other icon in the
  // strip; the actions live in the panel it opens. BarIconButton fits whatever
  // it is handed to the bar's icon size from its painted ink, so the mark is
  // drawn into a fixed, clipped box: a Shape does not scale its own path to
  // its width and height. The paths live in the SVG's 187x187 space, so the
  // box scale is 24/147 — the bars span x 40..147 of it.
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // No tooltip: the panel is the detail view, exactly as the shell's own
    // weather, clock and audio widgets do it.
    tooltipText: ""
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.openHub()
      else root.toggle()
    }

    iconComponent: Component {
      Item {
        width: 24
        height: 24
        clip: true
        opacity: root.appOn ? 1.0 : 0.45
        Behavior on opacity {
          NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
        }
        // The pulse, the way the Superwhisper panel's own status item beats:
        // while dictation is live the mark breathes between full and dim in
        // the urgent colour. Stopping hands opacity back to the binding.
        SequentialAnimation on opacity {
          id: recordPulse
          running: root.recording
          loops: Animation.Infinite
          NumberAnimation { to: 0.3; duration: 320; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1.0; duration: 320; easing.type: Easing.InOutQuad }
        }
        Shape {
          width: 187
          height: 187
          scale: 0.16
          transformOrigin: Item.TopLeft
          preferredRendererType: Shape.CurveRenderer
          smooth: true
          antialiasing: true
          ShapePath {
            fillColor: root.barIconColor
            strokeColor: "transparent"
            strokeWidth: 1
            PathSvg { path: root.barPath1 }
          }
          ShapePath {
            fillColor: root.barIconColor
            strokeColor: "transparent"
            strokeWidth: 1
            PathSvg { path: root.barPath2 }
          }
          ShapePath {
            fillColor: root.barIconColor
            strokeColor: "transparent"
            strokeWidth: 1
            PathSvg { path: root.barPath3 }
          }
          ShapePath {
            fillColor: root.barIconColor
            strokeColor: "transparent"
            strokeWidth: 1
            PathSvg { path: root.barPath4 }
          }
          ShapePath {
            fillColor: root.barIconColor
            strokeColor: "transparent"
            strokeWidth: 1
            PathSvg { path: root.barPath5 }
          }
        }
      }
    }
  }

  // owner: root is what makes this the bar's popout: KeyboardPanel asks the bar
  // for it, so the accent indicator appears under the icon, opening another
  // widget's panel closes this one, and Tab moves between them.
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(560))

    content: PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "o" || t === "O") root.openHub()
        else if (t === "d" || t === "D") root.dictate()
        else if (t === "p" || t === "P") root.power()
      }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        Row {
          spacing: Style.space(10)
          // The mark's own paths in a fixed box, as in the bar: the Shape is
          // drawn at 187 and scaled down, or the bars spill over the header.
          Item {
            width: 34
            height: 34
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            Shape {
              width: 187
              height: 187
              scale: 0.182
              transformOrigin: Item.TopLeft
              preferredRendererType: Shape.CurveRenderer
              smooth: true
              antialiasing: true
              ShapePath {
                fillColor: root.barIconColor
                strokeColor: "transparent"
                strokeWidth: 1
                PathSvg { path: root.barPath1 }
              }
              ShapePath {
                fillColor: root.barIconColor
                strokeColor: "transparent"
                strokeWidth: 1
                PathSvg { path: root.barPath2 }
              }
              ShapePath {
                fillColor: root.barIconColor
                strokeColor: "transparent"
                strokeWidth: 1
                PathSvg { path: root.barPath3 }
              }
              ShapePath {
                fillColor: root.barIconColor
                strokeColor: "transparent"
                strokeWidth: 1
                PathSvg { path: root.barPath4 }
              }
              ShapePath {
                fillColor: root.barIconColor
                strokeColor: "transparent"
                strokeWidth: 1
                PathSvg { path: root.barPath5 }
              }
            }
          }
          Column {
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
            Text {
              textFormat: Text.PlainText
              text: "Wispr Flow"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Text {
              textFormat: Text.PlainText
              text: root.statusText
              color: root.recording ? root.recordColor : root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.hairline
        }

        // One row per action; the power row flips with the app's state and the
        // dictation row follows the live recording state.
        Column {
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: {
              var rows = [{ id: "power", label: root.appOn ? "Quit Wispr Flow" : "Start Wispr Flow" }]
              if (root.appOn) {
                rows.push({ id: "hub", label: "Open Hub" })
                rows.push({ id: "dictate", label: root.recording ? "Stop dictation" : "Start hands-free dictation" })
                rows.push({ id: "restart", label: "Restart Wispr Flow" })
              }
              return rows
            }
            Rectangle {
              required property var modelData
              width: parent.width
              height: Style.space(30)
              radius: Style.space(6)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Style.space(10)
                textFormat: Text.PlainText
                text: modelData.label
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                width: parent.width - Style.space(20)
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.id === "power") { root.power(); root.close() }
                  else if (modelData.id === "hub") { root.openHub(); root.close() }
                  else if (modelData.id === "dictate") root.dictate()
                  else if (modelData.id === "restart") { root.restartApp(); root.close() }
                }
              }
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.appOn ? "" : "Wispr Flow is not running. Start it here, or from the app grid."
          wrapMode: Text.WordWrap
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          visible: text !== ""
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.hairline
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: "Esc closes · Tab next panel · o Hub · d dictate · p power"
          wrapMode: Text.WordWrap
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
