import QtQuick
import Quickshell.Io

Column {
    id: weatherRoot
    spacing: 4

    property string weatherTemp: "--"
    property string weatherFeelsLike: "--"
    property string weatherDesc: "Loading..."
    property string weatherGlyph: "cloud"

    Component.onCompleted: weatherFetcher.running = true

    Timer {
        interval: 900000 
        running: weatherRoot.visible
        repeat: true
        onTriggered: weatherFetcher.running = true
    }

    Text {
        text: weatherRoot.weatherGlyph
        font.family: "Material Symbols Outlined"
        font.pixelSize: 38
        color: "#ffffff"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        text: weatherRoot.weatherTemp
        font.family: "Google Sans Flex"
        font.pixelSize: 24
        font.weight: Font.Bold
        color: "#ffffff"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        text: weatherRoot.weatherDesc + "  •  Feels " + weatherRoot.weatherFeelsLike
        font.family: "Google Sans Flex"
        font.pixelSize: 12
        color: Qt.rgba(1, 1, 1, 0.5)
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.35)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }

    Process {
        id: weatherFetcher
        command: ["curl", "-s", "https://wttr.is/?format=j1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text);
                    let current = data.current_condition[0];
                    weatherRoot.weatherTemp = current.temp_F + "°F";
                    weatherRoot.weatherFeelsLike = current.FeelsLikeF + "°F";
                    let code = current.weatherCode.toString();
                    
                    let descMap = { "0": "Clear Sky", "1": "Mainly Clear", "2": "Partly Cloudy", "3": "Overcast", "45": "Foggy", "48": "Rime Fog", "51": "Light Drizzle", "53": "Moderate Drizzle", "55": "Dense Drizzle", "61": "Slight Rain", "63": "Moderate Rain", "65": "Heavy Rain", "71": "Light Snow", "73": "Moderate Snow", "75": "Heavy Snow", "80": "Light Showers", "85": "Light Snow Showers", "95": "Thunderstorm" };
                    let iconMap = { "0": "clear_day", "1": "partly_cloudy_day", "2": "partly_cloudy_day", "3": "cloudy", "45": "foggy", "48": "foggy", "51": "rainy", "53": "rainy", "55": "rainy", "61": "rainy", "63": "rainy", "65": "rainy", "71": "snowing", "73": "snowing", "75": "snowing", "80": "rainy", "85": "snowing", "95": "thunderstorm" };

                    weatherRoot.weatherDesc = descMap[code] !== undefined ? descMap[code] : current.weatherDesc[0].value;
                    weatherRoot.weatherGlyph = iconMap[code] !== undefined ? iconMap[code] : "cloud";
                } catch (e) {}
                weatherFetcher.running = false;
            }
        }
    }
}