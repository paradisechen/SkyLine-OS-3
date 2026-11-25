import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    readonly property alias games: gamesFiltered

    function currentGame(index) {
        if (currentCollection == -1)
            return api.allGames.get(lastPlayedGames.mapToSource(gamesHidden.mapToSource(index)));
        else
            return api.collections.get(currentCollection).games.get(lastPlayedGames.mapToSource(gamesHidden.mapToSource(index)));
    }

    property int max: 10

    SortFilterProxyModel {
        id: lastPlayedGames
        sourceModel: (currentCollection == -1) ? api.allGames : api.collections.get(currentCollection).games
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }

    SortFilterProxyModel {
        id: gamesHidden
        sourceModel: lastPlayedGames
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
        filters: IndexFilter { maximumIndex: Math.min(9, max - 1) }
    }

    property var collection: {
        return {
            name: "Home Recent",
            shortName: "homerecent",
            games: gamesFiltered
        };
    }
}
