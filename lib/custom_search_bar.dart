import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final SearchController searchController; //
  final void Function(String)? onSearchChanged;

  const CustomSearchBar({
    Key? key,
    required this.searchController,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      child: SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: searchController,
            onTap: () {
              searchController.openView();
            },
            onChanged: (String query) {
              searchController.openView();
              if (onSearchChanged != null) {
                onSearchChanged!(query); // 검색어 변경 시 외부에서 전달된 콜백 호출
              }
            },
            backgroundColor: WidgetStateProperty.all(Colors.white),
            hintText: "검색어를 입력해주세요",
            hintStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.grey),
            ),
            trailing: const <Widget>[
              Icon(
                Icons.search,
                color: Colors.grey,
              ),
            ],
            // 검생창 크기 조절
            // constraints: BoxConstraints(maxWidth: , maxHeight: ),
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return List<ListTile>.generate(
            5,
                (int index) {
              final String item = 'item $index';
              return ListTile(
                title: Text(item),
                onTap: () {
                  controller.closeView(item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
