import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    readonly property alias games: gamesFiltered

    function currentGame(index) {
        if (currentCollection == -1)
            return api.allGames.get(mostPlayedGames.mapToSource(index));
        else
            return api.collections.get(currentCollection).games.get(mostPlayedGames.mapToSource(index));
    }

    property int max: mostPlayedGames.count

    SortFilterProxyModel {
        id: mostPlayedGames
        sourceModel: (currentCollection == -1) ? api.allGames : api.collections.get(currentCollection).games
        sorters: [
            RoleSorter { roleName: "favorite"; sortOrder: Qt.DescendingOrder },
            RoleSorter { roleName: "playTime"; sortOrder: Qt.DescendingOrder }
        ]
    }

    SortFilterProxyModel {
        id: gamesFiltered
        sourceModel: mostPlayedGames
        filters: IndexFilter { maximumIndex: max - 1 }
    }

    property var collection: {
        return {
            name: "Most Played Games",
            shortName: "mostplayed",
            games: gamesFiltered
        };
    }
}
