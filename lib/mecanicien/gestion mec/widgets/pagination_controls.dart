import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int page;
  final int pageCount;
  final int pageSize;
  final Function() onPrevPage;
  final Function() onNextPage;
  final Function(int) onPageSizeChanged;

  const PaginationControls({
    super.key,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Page ${page + 1} / ${pageCount == 0 ? 1 : pageCount}'),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: page > 0 ? onPrevPage : null,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: (page + 1) < pageCount ? onNextPage : null,
        ),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: pageSize,
          items: const [
            DropdownMenuItem(value: 5, child: Text('5')),
            DropdownMenuItem(value: 8, child: Text('8')),
            DropdownMenuItem(value: 12, child: Text('12')),
            DropdownMenuItem(value: 20, child: Text('20')),
          ],
          onChanged: (v) => onPageSizeChanged(v!),
        ),
      ],
    );
  }
}