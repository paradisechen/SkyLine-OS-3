import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    readonly property alias games: gamesFiltered

    function currentGame(index) {
        if (currentCollection == -1)
            return api.allGames.get(gamesSource.mapToSource(gamesHidden.mapToSource(index)));
        else
            return api.collections.get(currentCollection).games.get(gamesSource.mapToSource(gamesHidden.mapToSource(index)));
    }

    property int max: gamesFiltered.count
    property string searchTerm: ""

    SortFilterProxyModel {
        id: gamesSource
        sourceModel: (currentCollection == -1) ? api.allGames : api.collections.get(currentCollection).games
        sorters: [
            RoleSorter { roleName: "favorite"; sortOrder: Qt.DescendingOrder },
            RoleSorter { roleName: "title"; sortOrder: Qt.AscendingOrder }
        ]
        filters: RegExpFilter { roleName: "title"; pattern: searchTerm; caseSensitivity: Qt.CaseInsensitive; enabled: searchTerm != "" }
    }

    SortFilterProxyModel {
        id: gamesHidden
        sourceModel: gamesSource
        filters: ExpressionFilter {
            expression: {
                hiddenApps;
                var showHidden = api.memory.get("Show Hidden Apps") === "Yes";
                return showHidden || !isAppHidden(model.title);
            }
        }
    }

    SortFilterProxyModel {
        id: gamesFiltered
        sourceModel: gamesHidden
    }

    property var collection: {
        return {
            name: "All games",
            shortName: "allgames",
            games: gamesFiltered
        };
    }
}
