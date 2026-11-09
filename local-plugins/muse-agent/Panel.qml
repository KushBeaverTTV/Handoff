import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Muse — Meta's personal AI agent. One bar icon carrying the headline usage
// figure; a click opens the panel with every window's meter, the way the
// shell's own weather, clock and audio widgets do. This is Muse the agent
// (muse.ai), not Muse Code, the terminal coding agent, which is a separate
// product with its own CLI and its own usage records.
//
// The figures come from ~/.local/bin/muse-usage.cjs, which reads them out of
// the running web app over CDP (muse.ai publishes no usage API) and writes
// ~/.cache/omarchy/muse-usage.json.
Panel {
  id: root
  moduleName: "muse-agent"
  ipcTarget: "muse"
  // This plugin owns its own IPC surface; the base's open/close/toggle would
  // otherwise claim the same target.
  manageIpc: false

  readonly property string url: "https://muse.ai"
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string usageFile: root.home + "/.cache/omarchy/muse-usage.json"
  readonly property string usageScript: root.home + "/.local/bin/muse-usage.cjs"

  // The Muse mark's own path, from the logo SVG muse.ai ships. Drawn as a
  // Shape rather than that SVG because Qt's renderer drops the site's
  // gradient (display-p3 colour() stops) and paints the mark black.
  readonly property string logoPath: "M24.6257 16.1214C28.2365 16.1214 30.8187 18.9408 30.8187 23.3643C30.8185 27.7868 30.1055 31.7765 28.9225 40.2466C28.0743 46.1813 26.62 55.2418 26.0132 59.0088C27.1782 56.7815 29.9074 51.5757 30.3914 50.5982C36.1081 39.061 42.0657 28.7544 43.7826 26.0254C46.0594 22.382 48.062 20.9229 51.1597 20.9229C52.7685 20.923 54.6826 21.7357 55.6315 22.819C56.9178 24.2895 57.1859 26.6602 57.1411 29.244C57.0738 33.2073 56.5599 39.5264 55.8553 46.5698C55.5416 49.7057 54.9365 56.1066 54.5288 60.4004C58.1883 53.8532 64.9609 41.8109 67.6921 37.6058C70.0727 33.9402 72.466 31.5797 75.6836 31.5796C78.4595 31.5796 81.8809 33.5416 81.6772 38.7573C81.3774 46.4556 80.2673 63.2232 79.7607 70.7479C83.1662 65.7913 87.6377 58.4543 89.3148 55.6966C91.0104 52.908 92.75 50.6542 95.3898 50.5778C98.0987 50.4995 99.913 52.341 99.9959 55.1839C100.078 58.0277 98.3835 61.2256 96.1344 64.856C93.6937 68.7957 90.9621 73.0123 87.6383 76.9491C84.3148 80.8856 81.2604 83.8782 76.5991 83.8786C72.4243 83.8786 69.4869 81.1043 69.283 76.0254C69.1768 73.364 69.6804 67.6405 70.0602 63.1673C70.5 57.9875 71.0315 52.9861 71.403 49.6786C67.7337 56.3979 60.0101 70.4676 56.5348 75.9603C53.1343 81.3339 51.4774 83.2269 47.8882 83.2275C44.2977 83.2275 42.7226 80.6416 42.6717 76.7497C42.6142 72.5285 45.7852 47.1821 46.8587 38.737C45.1183 42.4616 40.839 51.6056 38.1551 57.0435C35.5587 62.3055 31.204 71.3978 28.0436 76.6357C25.7668 80.4094 23.2092 83.2273 19.4173 83.2275C15.6252 83.2275 13.4847 80.6784 13.4847 76.5788C13.4847 72.4794 14.6716 65.6492 15.9465 57.1777C16.5839 53.0781 17.3108 48.6133 18.1315 43.8761C18.7324 40.448 19.7764 34.4169 20.4183 30.7129C17.502 35.2539 12.2536 43.4278 10.6567 45.8903C8.88113 48.6291 7.28747 50.626 4.64681 50.6266C1.7329 50.6266 0.000532901 48.3522 0 45.7113C0 43.0703 1.34323 41.0344 3.52376 37.4512C6.32403 32.8465 11.3578 26.57 14.1154 23.2747C17.3656 19.3912 20.6139 16.1219 24.6257 16.1214Z"
  readonly property color markColor: "#0082FB"
  readonly property color muted: Qt.darker(root.barForeground, 1.55)
  readonly property color hairline: Qt.darker(root.barForeground, 2.4)
  readonly property color barUrgent: root.bar ? (root.bar.urgent || Commons.Color.urgent) : Commons.Color.urgent

  // ---------------------------------------------------------------- usage
  property var windows: []
  property string plan: ""
  property string fetchedAt: ""
  property bool refreshing: false

  // The headline is the window furthest into its allowance, which is the one
  // worth watching; the bar shows just that figure.
  readonly property var headline: {
    if (!windows || windows.length === 0) return null
    var best = windows[0]
    for (var i = 1; i < windows.length; i++)
      if (Number(windows[i].percentUsed) > Number(best.percentUsed)) best = windows[i]
    return best
  }
  readonly property string usageLabel: headline ? String(headline.percentUsed) + "%" : ""
  readonly property bool urgent: !!headline && Number(headline.percentUsed) >= 90
  readonly property string ageText: {
    if (!fetchedAt) return ""
    var then = new Date(fetchedAt).getTime()
    if (!isFinite(then)) return ""
    var mins = Math.max(0, Math.round((Date.now() - then) / 60000))
    if (mins < 1) return "just now"
    if (mins < 60) return mins + " min ago"
    return Math.round(mins / 60) + " h ago"
  }

  FileView {
    id: usageFile
    path: root.usageFile
    watchChanges: true
    onLoaded: {
      try {
        var d = JSON.parse(text())
        root.windows = Array.isArray(d.windows) ? d.windows : []
        root.plan = String(d.plan || "")
        root.fetchedAt = String(d.fetchedAt || "")
      } catch (e) {
        // A half-written file leaves the last good figures on show.
      }
    }
  }

  Process {
    id: refreshProc
    running: false
    command: ["node", root.usageScript]
    onExited: root.refreshing = false
  }

  // Every fifteen minutes: often enough for a quota that resets weekly. The
  // scrape walks the Muse window through Settings, so it waits for a moment
  // when that window is not the one being used.
  Timer {
    interval: 900000
    running: true
    repeat: true
    onTriggered: root.refreshIfIdle()
  }

  readonly property bool museFocused: {
    var active = Hyprland.activeToplevel
    var ipc = active ? active.lastIpcObject : null
    return !!ipc && /muse\.ai/i.test(String(ipc.class || ""))
  }

  function refreshIfIdle() {
    if (!root.museFocused) root.refresh()
  }

  function refresh() {
    if (refreshProc.running) return
    root.refreshing = true
    refreshProc.running = true
  }

  // ---------------------------------------------------------------- window
  readonly property var museWindow: {
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var toplevel = toplevels[i]
      var ipc = toplevel.lastIpcObject
      if (!ipc) continue
      if (/muse\.ai/i.test(String(ipc.class || ""))) return toplevel
      if (/muse/i.test(String(ipc.title || ""))) return toplevel
    }
    return null
  }
  readonly property bool running: museWindow !== null
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family

  function openMuse() {
    if (root.bar) root.bar.run("omarchy launch or focus webapp muse " + root.url)
  }

  // Reachable from a keybinding or the command line:
  //   omarchy-shell muse open | status | toggle | refresh
  IpcHandler {
    id: ipc
    target: root.ipcTarget
    function open(): string { root.openMuse(); return "ok" }
    function status(): string { return root.running ? "running" : "closed" }
    function toggle(): string { root.toggle(); return root.opened ? "open" : "closed" }
    function refresh(): string { root.refresh(); return root.refreshing ? "refreshing" : "busy" }
    Component.onCompleted: IpcRegistry.register(ipc)
    Component.onDestruction: IpcRegistry.unregister(ipc)
  }

  Component.onCompleted: Qt.callLater(root.refresh)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The bar carries the Muse mark, sized like every other icon in the strip; the
  // usage figures live in the panel it opens. BarIconButton fits whatever it is
  // handed to the bar's icon size from its painted ink, so the mark is drawn
  // into a fixed, clipped box: a Shape does not scale its 100x100 path to its own
  // width and height, and left unboxed the ink measures as the whole path.
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // No tooltip: the panel is the detail view, exactly as the shell's own
    // weather, clock and audio widgets do it.
    tooltipText: ""
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.openMuse()
      else root.toggle()
    }

    iconComponent: Component {
      Item {
        width: 24
        height: 24
        clip: true
        opacity: root.running ? 1.0 : 0.45
        Behavior on opacity {
          NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
        }
        Shape {
          width: 100
          height: 100
          scale: 0.24
          transformOrigin: Item.TopLeft
          preferredRendererType: Shape.CurveRenderer
          smooth: true
          antialiasing: true
          ShapePath {
            fillColor: root.markColor
            strokeColor: "transparent"
            strokeWidth: 1
            PathSvg { path: root.logoPath }
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
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(560))

    content: PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "o" || t === "O") root.openMuse()
        else if (t === "r" || t === "R") root.refresh()
      }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        Row {
          spacing: Style.space(10)
          // The path lives in a 100x100 coordinate space and a Shape does not
          // scale its path to its own size, so the Shape is drawn at 100 and
          // scaled down into a fixed box. Sizing the Shape alone leaves the
          // mark at full size, spilling over everything below the header.
          Item {
            width: 34
            height: 34
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            Shape {
              width: 100
              height: 100
              scale: 0.34
              transformOrigin: Item.TopLeft
              preferredRendererType: Shape.CurveRenderer
              smooth: true
              antialiasing: true
              ShapePath {
                fillColor: root.markColor
                strokeColor: "transparent"
                strokeWidth: 1
                PathSvg { path: root.logoPath }
              }
            }
          }
          Column {
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
            Text {
              textFormat: Text.PlainText
              text: "Muse"
              color: root.barForeground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Text {
              textFormat: Text.PlainText
              text: root.plan !== "" ? root.plan + " plan" : (root.running ? "Running" : "Not running")
              color: root.muted
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

        // One meter per allowance window.
        Column {
          width: parent.width
          spacing: Style.space(12)
          visible: root.windows.length > 0

          Repeater {
            model: root.windows
            Column {
              required property var modelData
              width: parent.width
              spacing: Style.space(4)

              Row {
                width: parent.width
                Text {
                  textFormat: Text.PlainText
                  text: modelData.name || "Window"
                  color: root.barForeground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width * 0.55
                }
                Text {
                  textFormat: Text.PlainText
                  width: parent.width * 0.45
                  horizontalAlignment: Text.AlignRight
                  text: modelData.percentUsed + "% used"
                  color: Number(modelData.percentUsed) >= 90 ? root.barUrgent : root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              Rectangle {
                width: parent.width
                height: Style.space(6)
                radius: height / 2
                color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.15)
                Rectangle {
                  width: parent.width * Math.max(0, Math.min(100, Number(modelData.percentUsed))) / 100
                  height: parent.height
                  radius: parent.radius
                  color: Number(modelData.percentUsed) >= 90 ? root.barUrgent : root.markColor
                  Behavior on width {
                    NumberAnimation { duration: Style.duration(220); easing.type: Easing.OutCubic }
                  }
                }
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: modelData.left || ""
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(4)
          visible: root.windows.length === 0
          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "No usage figures yet. They are read out of the Muse web app, which has to be open and signed in."
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.hairline
        }

        Row {
          width: parent.width
          spacing: Style.space(8)
          Text {
            id: updatedText
            textFormat: Text.PlainText
            text: root.ageText !== "" ? "Updated " + root.ageText : "Not updated yet"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }
          // Whatever is left once the text and both buttons (78 + 88) and the
          // three gaps between the four items are placed. A fixed figure here
          // pushed the last button past the panel's edge.
          Item {
            width: Math.max(0, parent.width - updatedText.implicitWidth - 78 - 88 - parent.spacing * 3)
            height: 1
          }
          Rectangle {
            width: 78
            height: Style.space(30)
            radius: Style.space(6)
            color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.12)
            anchors.verticalCenter: parent.verticalCenter
            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: root.refreshing ? "…" : "Refresh"
              color: root.barForeground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.refresh()
            }
          }
          Rectangle {
            width: 88
            height: Style.space(30)
            radius: Style.space(6)
            color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.12)
            anchors.verticalCenter: parent.verticalCenter
            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: "Open Muse"
              color: root.barForeground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.openMuse(); root.close() }
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: "Esc closes · Tab next panel · r refresh · o open"
          wrapMode: Text.WordWrap
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
