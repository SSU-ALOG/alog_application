import 'package:flutter/material.dart';
import 'custom_chip.dart'; // CustomChip 임포트

class CustomChoiceChipGroup extends StatefulWidget {
  final List<String> options; // 선택 가능한 옵션 리스트
  final void Function(String)? onSelectionChanged; // 선택 상태 변경 콜백
  final String initialSelected; // 초기 선택된 값 설정

  const CustomChoiceChipGroup({
    Key? key,
    required this.options,
    this.onSelectionChanged,
    this.initialSelected = '',
  }) : super(key: key);

  @override
  _CustomChoiceChipGroupState createState() => _CustomChoiceChipGroupState();
}

class _CustomChoiceChipGroupState extends State<CustomChoiceChipGroup> {
  String _selectedOption = ''; // 현재 선택된 옵션

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialSelected; // 초기 선택 값 설정
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // 가로 스크롤
      child: Row(
        children: widget.options.map((String option) {
          final bool isSelected = _selectedOption == option;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: CustomChip(
              label: option,
              isSelected: isSelected,
              onSelected: () {
                setState(() {
                  _selectedOption = option; // 선택된 항목 업데이트
                });
                if (widget.onSelectionChanged != null) {
                  widget.onSelectionChanged!(option); // 선택 변경 시 콜백 호출
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
