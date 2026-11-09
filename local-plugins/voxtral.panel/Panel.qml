import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Mistral Voxtral dictation — bar mark is the official Voxtral model icon
// (pixel mark from mistral.ai brand). Live state from the status file written
// by omarchy-dictation-voxtral.
Panel {
  id: root
  moduleName: "voxtral"
  ipcTarget: "voxtral"
  manageIpc: false

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string pluginDir: root.home + "/.config/omarchy/plugins/voxtral.panel"
  readonly property string statusScript: root.pluginDir + "/voxtral-status.sh"
  readonly property string iconPath: Qt.resolvedUrl("assets/voxtral.png")
  readonly property string lastTextPath: root.home + "/.local/state/omarchy-dictation-voxtral/last_text"
  readonly property string logPath: root.home + "/.local/state/omarchy-dictation-voxtral/last.log"

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color muted: Qt.darker(foreground, 1.55)
  readonly property color hairline: Qt.darker(foreground, 2.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Official Voxtral / Mistral palette
  readonly property color brandBlue: "#0082E6"
  readonly property color brandDeep: "#044298"
  readonly property color brandLight: "#B9DAFF"
  readonly property color brandOrange: "#FA500F"
  readonly property color recordColor: brandOrange
  readonly property color workColor: brandBlue
  readonly property color errorColor: "#E11414"

  // idle | recording | processing | error | nokey
  property string state: "idle"
  property string lastText: ""

  readonly property bool recording: root.state === "recording"
  readonly property bool processing: root.state === "processing"
  readonly property bool broken: root.state === "error" || root.state === "nokey"
  readonly property bool live: root.recording || root.processing

  readonly property color barIconColor: {
    if (root.recording) return root.recordColor
    if (root.processing) return root.workColor
    if (root.state === "error") return root.errorColor
    if (root.state === "nokey") return root.muted
    return root.foreground
  }

  readonly property string statusText: {
    if (root.state === "recording") return "Listening…"
    if (root.state === "processing") return root.polishOn ? "Transcribing + polish…" : "Transcribing with Voxtral…"
    if (root.state === "error") return "Last run failed — check log"
    if (root.state === "nokey") return "API key missing"
    return "Idle — hold Right Option (or Right Ctrl)"
  }

  readonly property string statusDetail: {
    if (root.state === "nokey")
      return "Put your Mistral key in ~/.config/omarchy/dictation-voxtral/api_key"
    if (root.lastText.length > 0)
      return "Last: " + root.lastText
    return "Alt+Space or Super+Shift+Space toggles · click starts/stops"
  }

  // ---------------------------------------------------------------- state

  Process {
    id: statusProc
    command: ["bash", root.statusScript]
    stdout: StdioCollector {
      onStreamFinished: {
        var s = String(this.text).trim()
        if (s === "idle" || s === "recording" || s === "processing" || s === "error" || s === "nokey")
          root.state = s
      }
    }
  }

  FileView {
    id: lastTextView
    path: root.lastTextPath
    watchChanges: true
    onLoaded: root.lastText = String(text()).trim()
    onFileChanged: reload()
  }

  // Poll fast while live so the bar feels instant; slow when idle.
  Timer {
    interval: root.live ? 250 : 900
    running: true
    repeat: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  function dictateStart() {
    if (root.bar) root.bar.run("omarchy-dictation start")
  }
  function dictateStop() {
    if (root.bar) root.bar.run("omarchy-dictation stop")
  }
  function dictateToggle() {
    if (root.bar) root.bar.run("omarchy-dictation toggle")
  }
  function openLog() {
    if (root.bar) root.bar.run("omarchy-launch-tui sh -c 'less +G ~/.local/state/omarchy-dictation-voxtral/last.log'")
  }
  function openKeyFile() {
    if (root.bar) root.bar.run("xdg-open ~/.config/omarchy/dictation-voxtral/api_key")
  }
  function openConfig() {
    if (root.bar) root.bar.run("xdg-open ~/.config/omarchy/dictation-voxtral/config.json")
  }
  function copyLast() {
    if (root.lastText.length > 0 && root.bar)
      root.bar.run("sh -c " + JSON.stringify("printf %s " + JSON.stringify(root.lastText) + " | wl-copy"))
  }
  function polishToggle() {
    if (!root.bar) return
    if (root.polishOn) root.bar.run("omarchy-dictation-voxtral polish-off")
    else root.bar.run("omarchy-dictation-voxtral polish-on")
    polishTimer.start()
  }
  function cycleStyle() {
    if (!root.bar) return
    var order = ["natural", "chat", "email", "code"]
    var i = order.indexOf(root.styleName)
    var next = order[(i < 0 ? 0 : i + 1) % order.length]
    root.bar.run("omarchy-dictation-voxtral style " + next)
    polishTimer.start()
  }

  property bool polishOn: true
  property string styleName: "natural"

  Process {
    id: configProc
    command: ["omarchy-dictation-voxtral", "config"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var d = JSON.parse(String(this.text))
          root.polishOn = d.polish !== false
          root.styleName = d.style || "natural"
        } catch (e) {}
      }
    }
  }
  Timer {
    id: polishTimer
    interval: 400
    onTriggered: { configProc.running = true }
  }
  Component.onCompleted: Qt.callLater(function() {
    statusProc.running = true
    lastTextView.reload()
    configProc.running = true
  })

  IpcHandler {
    id: ipc
    target: root.ipcTarget
    function open(): string { root.toggle(); return root.opened ? "open" : "closed" }
    function toggle(): string { root.toggle(); return root.opened ? "open" : "closed" }
    function status(): string { return root.state }
    function dictate(): string { root.dictateToggle(); return "toggled" }
    function start(): string { root.dictateStart(); return "starting" }
    function stop(): string { root.dictateStop(); return "stopping" }
    Component.onCompleted: IpcRegistry.register(ipc)
    Component.onDestruction: IpcRegistry.unregister(ipc)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: ""
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.dictateToggle()
      else root.toggle()
    }

    iconComponent: Component {
      Item {
        width: 24
        height: 24
        clip: true

        // Official Voxtral pixel mark
        Image {
          id: mark
          anchors.centerIn: parent
          width: 24
          height: 24
          source: root.iconPath
          sourceSize.width: 128
          sourceSize.height: 128
          fillMode: Image.PreserveAspectFit
          smooth: false
          mipmap: false
          asynchronous: false
          opacity: root.state === "nokey" ? 0.4 : 1.0
          Behavior on opacity {
            NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
          }
          // Pulse while listening / processing
          SequentialAnimation on opacity {
            running: root.live
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 320; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 320; easing.type: Easing.InOutQuad }
          }
        }

        // Accent ring while live (orange listen / blue process)
        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: "transparent"
          border.width: root.live ? 1.5 : 0
          border.color: root.recording ? root.recordColor : root.workColor
          opacity: root.live ? 0.9 : 0
          Behavior on opacity {
            NumberAnimation { duration: Style.duration(160) }
          }
        }

        // Tiny error pip
        Rectangle {
          visible: root.broken
          width: 6
          height: 6
          radius: 3
          anchors.right: parent.right
          anchors.top: parent.top
          color: root.state === "nokey" ? root.muted : root.errorColor
        }
      }
    }
  }

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
        if (t === "d" || t === "D") root.dictateToggle()
        else if (t === "l" || t === "L") root.openLog()
        else if (t === "k" || t === "K") root.openKeyFile()
        else if (t === "c" || t === "C") root.copyLast()
      }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        Row {
          spacing: Style.space(10)
          Image {
            width: 36
            height: 36
            source: root.iconPath
            sourceSize.width: 72
            sourceSize.height: 72
            fillMode: Image.PreserveAspectFit
            smooth: false
            anchors.verticalCenter: parent.verticalCenter
          }
          Column {
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
            Text {
              textFormat: Text.PlainText
              text: "Voxtral"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Text {
              textFormat: Text.PlainText
              text: "Mistral Speech-to-Text"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.statusText
          color: root.recording ? root.recordColor
               : root.processing ? root.workColor
               : root.broken ? root.errorColor
               : root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: root.live
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.statusDetail
          wrapMode: Text.WordWrap
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.hairline
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: {
              var rows = []
              if (root.recording)
                rows.push({ id: "stop", label: "Stop listening" })
              else if (root.processing)
                rows.push({ id: "busy", label: "Working… (wait)" })
              else
                rows.push({ id: "start", label: "Start dictation" })
              rows.push({ id: "polish", label: root.polishOn ? "Polish: ON (tap to disable)" : "Polish: OFF (tap to enable)" })
              rows.push({ id: "style", label: "Style: " + root.styleName + " (tap to cycle)" })
              if (root.lastText.length > 0)
                rows.push({ id: "copy", label: "Copy last transcript" })
              if (root.state === "nokey")
                rows.push({ id: "key", label: "Open API key file" })
              rows.push({ id: "cfg", label: "Open config / vocab files" })
              rows.push({ id: "log", label: "Open last log" })
              return rows
            }
            Rectangle {
              required property var modelData
              width: parent.width
              height: Style.space(30)
              radius: Style.space(6)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
              opacity: modelData.id === "busy" ? 0.55 : 1.0
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
                enabled: modelData.id !== "busy"
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (modelData.id === "start") { root.dictateStart(); root.close() }
                  else if (modelData.id === "stop") { root.dictateStop() }
                  else if (modelData.id === "polish") root.polishToggle()
                  else if (modelData.id === "style") root.cycleStyle()
                  else if (modelData.id === "copy") { root.copyLast(); root.close() }
                  else if (modelData.id === "key") { root.openKeyFile(); root.close() }
                  else if (modelData.id === "cfg") { root.openConfig(); root.close() }
                  else if (modelData.id === "log") { root.openLog(); root.close() }
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.hairline
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: "Hold Right Option or Right Ctrl = PTT · Alt+Space toggle · Esc closes · d dictate · c copy · l log"
          wrapMode: Text.WordWrap
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
