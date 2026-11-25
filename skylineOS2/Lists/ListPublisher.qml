import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    readonly property alias games: gamesFiltered

    function currentGame(index) {
        if (currentCollection == -1)
            return api.allGames.get(publisherGames.mapToSource(index));
        else
            return api.collections.get(currentCollection).games.get(publisherGames.mapToSource(index));
    }

    property int max: publisherGames.count

    SortFilterProxyModel {
        id: publisherGames
        sourceModel: (currentCollection == -1) ? api.allGames : api.collections.get(currentCollection).games
        sorters: [
            RoleSorter { roleName: "favorite"; sortOrder: Qt.DescendingOrder },
            RoleSorter { roleName: "publisher"; sortOrder: Qt.AscendingOrder }
        ]
    }

    SortFilterProxyModel {
        id: gamesFiltered
        sourceModel: publisherGames
        filters: IndexFilter { maximumIndex: max - 1 }
    }

    property var collection: {
        return {
            name: "Games By Publisher",
            shortName: "publisher",
            games: gamesFiltered
        };
    }
}
